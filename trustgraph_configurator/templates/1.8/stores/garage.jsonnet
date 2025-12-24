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
    "garage-region":: "garage",
    "garage-replication-factor":: "1",  // Set to 1 for single-node, 3 for production

    garage +: {
        create:: function(engine)

            // Garage configuration file - TOML format
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
            ||| % [$["garage-replication-factor"], $["garage-rpc-secret"], $["garage-region"]];

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
            local init_container =
                engine.container("garage-init")
                    .with_image(images.garage)
                    .with_environment({
                        GARAGE_ACCESS_KEY: $["garage-access-key"],
                        GARAGE_SECRET_KEY: $["garage-secret-key"],
                        GARAGE_REGION: $["garage-region"],
                    })
                    .with_limits("0.5", "256M")
                    .with_reservations("0.25", "128M")
                    .with_volume_mount(cfgVol, "/etc/garage/")
                    .with_command([
                        "bash", "-c", |||
                            set -e

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

                            # Get the node ID
                            echo "Getting Garage node ID..."
                            NODE_ID=$(garage -c /etc/garage/garage.toml node id | grep -oP 'Node ID: \K\w+')
                            echo "Node ID: ${NODE_ID}"

                            # Check if layout is already configured
                            if garage -c /etc/garage/garage.toml layout show 2>&1 | grep -q "${NODE_ID}"; then
                                echo "Layout already configured, skipping layout setup."
                            else
                                echo "Configuring Garage cluster layout..."
                                # Assign the node to zone "dc1" with 100GB capacity
                                garage -c /etc/garage/garage.toml layout assign ${NODE_ID} -z dc1 -c 100G
                                # Apply the layout configuration
                                garage -c /etc/garage/garage.toml layout apply --version 1
                                echo "Layout configured successfully."
                                # Wait for layout to stabilize
                                sleep 5
                            fi

                            # Check if key already exists (idempotent)
                            if garage -c /etc/garage/garage.toml key info "${GARAGE_ACCESS_KEY}" >/dev/null 2>&1; then
                                echo "Access key ${GARAGE_ACCESS_KEY} already exists, skipping creation."
                            else
                                echo "Creating S3 access key: ${GARAGE_ACCESS_KEY}"
                                garage -c /etc/garage/garage.toml key create "${GARAGE_ACCESS_KEY}"
                                garage -c /etc/garage/garage.toml key import \
                                    "${GARAGE_ACCESS_KEY}" \
                                    "${GARAGE_SECRET_KEY}" \
                                    --yes
                                echo "Access key created successfully."
                            fi

                            # Grant permissions to the key
                            echo "Granting permissions to ${GARAGE_ACCESS_KEY}..."
                            garage -c /etc/garage/garage.toml key allow \
                                --create-bucket \
                                --owner \
                                "${GARAGE_ACCESS_KEY}"

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
