local images = import "values/images.jsonnet";

// Distributed (multi-node) Qdrant: one bootstrap node plus N peers,
// forming a Raft consensus cluster.
//
// Slots in like a memory profile: include AFTER vector-store-qdrant in
// the config. It overrides the single-node "qdrant" deployment's
// create:: with a multi-node topology. The storage/query processors are
// untouched and keep addressing host "qdrant" on 6333 (url.qdrant), so
// node 0 deliberately keeps the name "qdrant".
//
// Enabling cluster mode forms Raft consensus; the embedding-store WRITE
// processors then create collections with the shard_number /
// replication_factor below so data is sharded and replicated across the
// ring. Both default to the ring size; keep replication_factor <= node
// count if you change peers.

{

    // Collection geometry the write processors apply when creating
    // collections. Ring size = default 2 peers + bootstrap = 3. Overrides
    // the single-node defaults of 1 from qdrant.jsonnet.
    "qdrant-replication-factor":: 3,
    "qdrant-shard-number":: 3,

    "qdrant" +: {

        // Memory settings (can be overridden by memory-profile)
        "memory-limit":: "1024M",
        "memory-reservation":: "1024M",

        // Number of peer nodes in addition to the bootstrap node.
        // 2 peers -> a 3-node cluster (sensible quorum).
        "peers":: 2,

        create:: function(engine)

            local memLimit = self["memory-limit"];
            local memReserv = self["memory-reservation"];
            local peers = self["peers"];

            // P2P/consensus endpoint of the bootstrap node (node 0).
            local bootstrapUri = "http://qdrant:6335";

            // Build a single Qdrant node. Node 0 is the bootstrap node
            // and keeps the name "qdrant" so url.qdrant keeps resolving;
            // peers are qdrant-peer-N.
            local mkNode = function(index)

                local isBootstrap = index == 0;
                local name =
                    if isBootstrap then "qdrant"
                    else "qdrant-peer-%d" % index;
                local selfUri = "http://%s:6335" % name;

                local vol = engine.volume(name).with_size("20G");

                // --uri tells peers how to reach this node; the bootstrap
                // node must supply it. Peers also pass --bootstrap to
                // discover the cluster.
                local entrypoint =
                    if isBootstrap then
                        [ "./qdrant", "--uri", selfUri ]
                    else
                        [
                            "./qdrant",
                            "--bootstrap", bootstrapUri,
                            "--uri", selfUri,
                        ];

                local container =
                    engine.container(name)
                        .with_image(images.qdrant)
                        .with_user(1000)
                        .with_group(1000)
                        .with_environment({
                            QDRANT__CLUSTER__ENABLED: "true",
                        })
                        .with_entrypoint(entrypoint)
                        .with_limits("1.0", memLimit)
                        .with_reservations("0.5", memReserv)
                        .with_volume_mount(vol, "/qdrant/storage");

                local containerSet = engine.containers(name, [ container ]);

                // Internal-only service. 6333 REST / 6334 gRPC are the
                // client ports; 6335 is the P2P/consensus channel and
                // must stay internal.
                local service =
                    engine.internalService(name, containerSet)
                    .with_port(6333, 6333, "api")
                    .with_port(6334, 6334, "api2")
                    .with_port(6335, 6335, "p2p");

                [ vol, containerSet, service ];

            local nodes = std.flattenArrays([
                mkNode(i)
                for i in std.range(0, peers)
            ]);

            engine.resources(nodes)

    },

}
