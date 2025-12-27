local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";

{
    with:: function(key, value)
        self + {
            ["garage-" + key]:: value,
        },

    // Garage credentials and cluster settings
    "garage-access-key":: "object-user",
    "garage-secret-key":: "object-password",
    "garage-rpc-secret":: "bbba746a9e289bad64a9e7a36a4299dac8d6e0b8cc2a6c2937fe756df4492008",
    // For a production system, override this value
    "garage-admin-token":: "batts-rockhearted-unpartially",
    "garage-region":: "garage",
    "garage-replication-factor":: "1",  // Set to 1 for single-node, 3 for production

    garage +: {
        create:: function(engine)

            // Garage daemon configuration file - TOML format
            local garage_conf = |||
                metadata_dir = "/var/lib/garage/meta"
                data_dir = "/var/lib/garage/data"

                db_engine = "lmdb"

                replication_factor = %s

                compression_level = 1

                rpc_bind_addr = "[::]:3901"
                rpc_public_addr = "[::]:3901"
                rpc_secret = "%s"

                [s3_api]
                s3_region = "%s"
                api_bind_addr = "[::]:3900"
                root_domain = ".s3.garage.local"

                [s3_web]
                bind_addr = "[::]:3902"
                root_domain = ".web.garage.local"
                index = "index.html"

                [k2v_api]
                api_bind_addr = "[::]:3904"

                [admin]
                api_bind_addr = "[::]:3903"
                admin_token = "%s"
            ||| % [$["garage-replication-factor"], $["garage-rpc-secret"], $["garage-region"], $["garage-admin-token"]];

            // Config volume - contains the rendered garage.toml
            local cfgVol = engine.configVolume(
                "garage-cfg", "garage",
                {
                    "garage.toml": garage_conf,
                }
            );

            // Volumes - Garage stores metadata and data separately
            local vol_meta = engine.volume("garage-meta").with_size("5G");
            local vol_data = engine.volume("garage-data").with_size("100G");

            // Main Garage daemon container
            local garage_container =
                engine.container("garage")
                    .with_image(images.garage)
                    .with_command([
                        "/garage", "-c", "/etc/garage/garage.toml", "server"
                    ])
                    .with_environment({
                        RUST_LOG: "garage=info",
                    })
                    .with_limits("1.0", "1024M")
                    .with_reservations("0.5", "512M")
                    .with_port(3900, 3900, "s3-api")
                    .with_port(3901, 3901, "rpc")
                    .with_port(3902, 3902, "web")
                    .with_port(3903, 3903, "admin")
                    .with_port(3904, 3904, "k2v")
                    .with_volume_mount(cfgVol, "/etc/garage/")
                    .with_volume_mount(vol_meta, "/var/lib/garage/meta")
                    .with_volume_mount(vol_data, "/var/lib/garage/data");

            // Init container - configures cluster layout and creates S3 credentials
            // IMPORTANT: This container exits with code 0 after completion
            // Orchestrator must NOT restart it (use K8s Job or Compose restart: "no")
            // Uses Alpine base image since garage container has no shell
            local init_container =
                engine.container("garage-init")
                    .with_image("docker.io/alpine:3.23.2")
                    .with_environment({
                        GARAGE_ACCESS_KEY: $["garage-access-key"],
                        GARAGE_SECRET_KEY: $["garage-secret-key"],
                        GARAGE_REGION: $["garage-region"],
                        GARAGE_ADMIN_TOKEN: $["garage-admin-token"],
                        GARAGE_RPC_SECRET: $["garage-rpc-secret"],
                    })
                    .with_limits("0.5", "256M")
                    .with_reservations("0.25", "128M")
                    .with_volume_mount(cfgVol, "/etc/garage/")
                    .with_command([
                        "sh", "-c", |||
                            set -e

                            # Install required tools
                            echo "Installing curl, jq and downloading garage CLI..."
                            apk add --no-cache curl jq

                            # Download garage binary (v1.0.1) for remote management
                            curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/v1.0.1/x86_64-unknown-linux-musl/garage" \
                                -o /usr/local/bin/garage
                            chmod +x /usr/local/bin/garage

                            echo "Waiting for Garage daemon to be ready..."
                            MAX_ATTEMPTS=60
                            ATTEMPT=0
                            until curl -sf http://garage:3903/health >/dev/null 2>&1; do
                                ATTEMPT=$((ATTEMPT+1))
                                if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
                                    echo "ERROR: Garage failed to become ready after ${MAX_ATTEMPTS} attempts"
                                    exit 1
                                fi
                                echo "Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: Garage not ready, retrying in 2s..."
                                sleep 2
                            done
                            echo "Garage daemon is ready."

                            # Get the node ID via Admin API
                            echo "Getting Garage node ID via Admin API..."
                            curl -s -H "Authorization: Bearer ${GARAGE_ADMIN_TOKEN}" \
                                http://garage:3903/v1/status > /tmp/garage-status.json

                            NODE_ID=$(jq -r '.node' /tmp/garage-status.json)
                            echo "Node ID: ${NODE_ID}"

                            if [ -z "$NODE_ID" ] || [ "$NODE_ID" = "null" ]; then
                                echo "ERROR: Failed to retrieve node ID"
                                exit 1
                            fi

                            # ===== LAYOUT MANAGEMENT VIA REMOTE RPC =====
                            # Use garage CLI with -h and -s flags to connect remotely
                            # -h requires format: <node-id>@<host>:<port>
                            # -s provides the RPC secret

                            # Construct full RPC identifier
                            RPC_HOST="${NODE_ID}@garage:3901"
                            echo "RPC Host: ${RPC_HOST}"

                            # Check current layout to see if node is already assigned (idempotent)
                            echo "Checking current cluster layout..."
                            LAYOUT_OUTPUT=$(garage -h "${RPC_HOST}" -s "${GARAGE_RPC_SECRET}" layout show 2>&1)

                            # Check if node already has a role assigned (look for capacity assignment)
                            if echo "$LAYOUT_OUTPUT" | grep -E "^\s+${NODE_ID:0:16}" | grep -q "100.0 GB"; then
                                echo "Node ${NODE_ID} already assigned in layout with 100GB capacity, skipping."
                            else
                                echo "Assigning node to cluster layout..."
                                # Assign node to zone dc1 with 100GB capacity
                                garage -h "${RPC_HOST}" -s "${GARAGE_RPC_SECRET}" \
                                    layout assign ${NODE_ID} -z dc1 -c 100G

                                echo "Applying layout configuration..."
                                # Get current staged version and apply
                                garage -h "${RPC_HOST}" -s "${GARAGE_RPC_SECRET}" \
                                    layout apply --version 1

                                echo "Layout configured successfully."
                                # Wait for layout to stabilize
                                sleep 5
                            fi

                            # ===== KEY MANAGEMENT VIA REMOTE RPC =====

                            # Check if key already exists (idempotent)
                            if garage -h "${RPC_HOST}" -s "${GARAGE_RPC_SECRET}" key info "${GARAGE_ACCESS_KEY}" >/dev/null 2>&1; then
                                echo "Access key ${GARAGE_ACCESS_KEY} already exists, skipping creation."
                            else
                                echo "Creating S3 access key with custom secret: ${GARAGE_ACCESS_KEY}"

                                # Generate a deterministic Garage key ID from the access key name
                                # Format: GK + 24 hex characters (12 bytes)
                                # Use SHA256 hash of access key name, take first 12 bytes
                                KEY_ID="GK$(echo -n "${GARAGE_ACCESS_KEY}" | sha256sum | cut -c1-24)"
                                echo "Using Key ID: ${KEY_ID}"

                                # Import key with custom secret (this creates the key)
                                garage -h "${RPC_HOST}" -s "${GARAGE_RPC_SECRET}" \
                                    key import "${KEY_ID}" "${GARAGE_SECRET_KEY}" --yes

                                # Rename the key to our desired name
                                garage -h "${RPC_HOST}" -s "${GARAGE_RPC_SECRET}" \
                                    key rename "${KEY_ID}" "${GARAGE_ACCESS_KEY}"

                                echo "Access key created and secret imported successfully."
                            fi

                            # Grant permissions to the key
                            echo "Granting permissions to ${GARAGE_ACCESS_KEY}..."
                            garage -h "${RPC_HOST}" -s "${GARAGE_RPC_SECRET}" \
                                key allow --create-bucket --owner "${GARAGE_ACCESS_KEY}"

                            echo "Garage initialization complete. S3 endpoint ready at http://garage:3900"
                            echo "Access Key: ${GARAGE_ACCESS_KEY}"
                            echo "Secret Key: ${GARAGE_SECRET_KEY}"
                            echo "Region: ${GARAGE_REGION}"
                            exit 0
                        |||,
                    ]);

            // Container sets
            local garage_containerSet = engine.containers("garage", [garage_container]);
            local init_containerSet = engine.containers("garage-init", [init_container]);

            // Service - expose Garage ports
            local garage_service =
                engine.service(garage_containerSet)
                    .with_port(3900, 3900, "s3-api")
                    .with_port(3901, 3901, "rpc")
                    .with_port(3902, 3902, "web")
                    .with_port(3903, 3903, "admin")
                    .with_port(3904, 3904, "k2v");

            engine.resources([
                cfgVol,
                vol_meta,
                vol_data,
                garage_containerSet,
                init_containerSet,
                garage_service,
            ])

    },

}
