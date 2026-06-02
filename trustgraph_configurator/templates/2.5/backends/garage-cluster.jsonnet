local images = import "values/images.jsonnet";

// Distributed (multi-node) Garage: a primary node plus N peers forming an
// S3-compatible cluster with real data replication.
//
// Slots in like a memory profile: include AFTER the garage-backed store
// in the config. It overrides the single-node "garage" deployment's
// create:: with a multi-node topology. The primary keeps the name
// "garage" so url.garage (garage:3900) and the librarian/processors
// connect unchanged; peers are garage-peer-N.
//
// Unlike Qdrant/Cassandra, Garage replication is a daemon-config setting
// (replication_factor in garage.toml), so this is a pure-templates change
// - no TrustGraph processor work needed for data to actually replicate.
//
// Membership is explicitly orchestrated by the garage-init container
// (connect peers -> assign layout -> apply), so there is no gossip
// startup race: the init script waits for every daemon before wiring the
// cluster. Each node is placed in its own zone (dc1, dc2, ...) so the
// replication factor can be satisfied across distinct failure domains.
//
// Note: replication-factor must be <= the number of nodes. The default
// (3 nodes, factor 3) is balanced; adjust both together.

{

    garage +: {

        // Garage S3 credentials (override for anything non-dev).
        "access-key":: "GK000000000000000000000001",
        "secret-key":: "b171f00be9be4c32c734f4c05fe64c527a8ab5eb823b376cfa8c2531f70fc427",
        "rpc-secret":: "bbba746a9e289bad64a9e7a36a4299dac8d6e0b8cc2a6c2937fe756df4492008",
        "admin-token":: "batts-rockhearted-unpartially",
        region:: "garage",

        // 3 nodes across 3 zones -> 3-way replication.
        "replication-factor":: "3",

        // Storage volume sizes (data-size also used as layout capacity).
        "meta-size":: "2G",
        "data-size":: "5G",

        // Number of peer nodes in addition to the primary.
        // 2 peers -> a 3-node cluster.
        "peers":: 2,

        create:: function(engine)

            local accessKey = self["access-key"];
            local secretKey = self["secret-key"];
            local rpcSecret = self["rpc-secret"];
            local adminToken = self["admin-token"];
            local region = self.region;
            local replicationFactor = self["replication-factor"];
            local metaSize = self["meta-size"];
            local dataSize = self["data-size"];
            local peers = self["peers"];

            // Node 0 keeps the name "garage" (the S3 endpoint clients use);
            // peers are garage-peer-N.
            local nodeName = function(index)
                if index == 0 then "garage"
                else "garage-peer-%d" % index;

            local nodeNames = [ nodeName(i) for i in std.range(0, peers) ];

            // garage.toml. rpc_public_addr is per-node so peers advertise a
            // routable address to each other.
            local garageConf = function(publicHost) |||
                metadata_dir = "/var/lib/garage/meta"
                data_dir = "/var/lib/garage/data"

                db_engine = "lmdb"

                replication_factor = %s

                compression_level = 1

                rpc_bind_addr = "[::]:3901"
                rpc_public_addr = "%s:3901"
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
            ||| % [replicationFactor, publicHost, rpcSecret, region, adminToken];

            // Build one Garage daemon node: own config + meta/data volumes.
            local mkNode = function(index)

                local name = nodeName(index);

                local cfgVol = engine.configVolume(
                    "garage-cfg-" + name, "garage/" + name,
                    {
                        "garage.toml": garageConf(name),
                    }
                );

                local volMeta =
                    engine.volume(name + "-meta").with_size(metaSize);
                local volData =
                    engine.volume(name + "-data").with_size(dataSize);

                local container =
                    engine.container(name)
                        .with_image(images.garage)
                        .with_user(1000)
                        .with_group(1000)
                        .with_command([
                            "/garage", "-c", "/etc/garage/garage.toml",
                            "server",
                        ])
                        .with_environment({
                            RUST_LOG: "garage=info",
                        })
                        .with_limits("1.0", "512M")
                        .with_reservations("0.5", "512M")
                        .with_volume_mount(cfgVol, "/etc/garage/")
                        .with_volume_mount(volMeta, "/var/lib/garage/meta")
                        .with_volume_mount(volData, "/var/lib/garage/data");

                local containerSet = engine.containers(name, [ container ]);

                // Internal-only service. 3900 S3 / 3902 web / 3904 k2v are
                // client ports; 3901 RPC and 3903 admin are how peers and
                // the init container reach each node.
                local service =
                    engine.internalService(name, containerSet)
                    .with_port(3900, 3900, "s3-api")
                    .with_port(3901, 3901, "rpc")
                    .with_port(3902, 3902, "web")
                    .with_port(3903, 3903, "admin")
                    .with_port(3904, 3904, "k2v");

                [ cfgVol, volMeta, volData, containerSet, service ];

            local nodeResources = std.flattenArrays([
                mkNode(i)
                for i in std.range(0, peers)
            ]);

            // Init container - connects peers, assigns the cluster layout
            // and imports the S3 key. One-shot: exits 0 on success (the
            // default on-failure restart won't re-run it).
            local init_container =
                engine.container("garage-init")
                    .with_image("docker.io/alpine:3.23.2")
                    .with_environment({
                        GARAGE_ACCESS_KEY: accessKey,
                        GARAGE_SECRET_KEY: secretKey,
                        GARAGE_REGION: region,
                        GARAGE_ADMIN_TOKEN: adminToken,
                        GARAGE_RPC_SECRET: rpcSecret,
                        GARAGE_DATA_SIZE: dataSize,
                        // Space-separated node hostnames; node 0 is primary.
                        GARAGE_NODES: std.join(" ", nodeNames),
                        GARAGE_PRIMARY: "garage",
                    })
                    .with_limits("0.5", "256M")
                    .with_reservations("0.25", "128M")
                    .with_command([
                        "sh", "-c", |||
                            set -e

                            echo "Installing curl, jq and downloading garage CLI..."
                            apk add --no-cache curl jq
                            curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/v2.1.0/x86_64-unknown-linux-musl/garage" \
                                -o /usr/local/bin/garage
                            chmod +x /usr/local/bin/garage

                            # Fetch a node's own ID via its Admin API.
                            get_node_id() {
                                curl -s -H "Authorization: Bearer ${GARAGE_ADMIN_TOKEN}" \
                                    "http://$1:3903/v2/GetNodeInfo?node=self" \
                                    | jq -r '.success | to_entries[0].value.nodeId'
                            }

                            # Wait for every daemon to answer on its admin port.
                            for node in $GARAGE_NODES; do
                                echo "Waiting for $node to be ready..."
                                ATTEMPT=0
                                until curl -s "http://${node}:3903/health" >/dev/null 2>&1; do
                                    ATTEMPT=$((ATTEMPT+1))
                                    if [ $ATTEMPT -ge 60 ]; then
                                        echo "ERROR: $node not ready after 60 attempts"
                                        exit 1
                                    fi
                                    sleep 2
                                done
                                echo "$node is ready."
                            done

                            PRIMARY_ID=$(get_node_id "$GARAGE_PRIMARY")
                            if [ -z "$PRIMARY_ID" ] || [ "$PRIMARY_ID" = "null" ]; then
                                echo "ERROR: could not get primary node ID"
                                exit 1
                            fi
                            PRIMARY_RPC="${PRIMARY_ID}@${GARAGE_PRIMARY}:3901"
                            echo "Primary RPC: ${PRIMARY_RPC}"

                            # Connect every peer to the primary (idempotent).
                            for node in $GARAGE_NODES; do
                                [ "$node" = "$GARAGE_PRIMARY" ] && continue
                                PEER_ID=$(get_node_id "$node")
                                echo "Connecting peer $node (${PEER_ID})..."
                                garage -h "$PRIMARY_RPC" -s "$GARAGE_RPC_SECRET" \
                                    node connect "${PEER_ID}@${node}:3901" || true
                            done
                            sleep 5

                            # Assign layout once. Idempotent: skip if the
                            # primary is already present in the layout.
                            PRIMARY_SHORT=$(echo "$PRIMARY_ID" | cut -c1-16)
                            LAYOUT=$(garage -h "$PRIMARY_RPC" -s "$GARAGE_RPC_SECRET" layout show 2>&1 || true)
                            if echo "$LAYOUT" | grep -q "$PRIMARY_SHORT"; then
                                echo "Layout already assigned, skipping."
                            else
                                ZONE=1
                                for node in $GARAGE_NODES; do
                                    NID=$(get_node_id "$node")
                                    echo "Assigning $node to zone dc${ZONE}..."
                                    garage -h "$PRIMARY_RPC" -s "$GARAGE_RPC_SECRET" \
                                        layout assign "$NID" -z "dc${ZONE}" -c "$GARAGE_DATA_SIZE"
                                    ZONE=$((ZONE+1))
                                done
                                echo "Applying layout..."
                                garage -h "$PRIMARY_RPC" -s "$GARAGE_RPC_SECRET" \
                                    layout apply --version 1
                                sleep 5
                            fi

                            # Import S3 key (idempotent) and grant bucket rights.
                            if garage -h "$PRIMARY_RPC" -s "$GARAGE_RPC_SECRET" key info "$GARAGE_ACCESS_KEY" >/dev/null 2>&1; then
                                echo "Access key already exists, skipping import."
                            else
                                echo "Importing S3 access key ${GARAGE_ACCESS_KEY}..."
                                garage -h "$PRIMARY_RPC" -s "$GARAGE_RPC_SECRET" \
                                    key import "$GARAGE_ACCESS_KEY" "$GARAGE_SECRET_KEY" --yes
                            fi
                            garage -h "$PRIMARY_RPC" -s "$GARAGE_RPC_SECRET" \
                                key allow --create-bucket "$GARAGE_ACCESS_KEY"

                            echo ""
                            echo "Garage cluster initialization complete!"
                            echo "S3 Endpoint: http://garage:3900 (region ${GARAGE_REGION})"
                            exit 0
                        |||,
                    ]);

            local init_containerSet =
                engine.containers("garage-init", [ init_container ]);

            engine.resources(nodeResources + [ init_containerSet ])

    },

}
