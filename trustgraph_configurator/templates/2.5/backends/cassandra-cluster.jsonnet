local images = import "values/images.jsonnet";

// Distributed (multi-node) Cassandra: a seed node plus N peers forming a
// gossip ring.
//
// Slots in like a memory profile: include AFTER the cassandra-backed
// store (triple-store-cassandra / row-store-cassandra) in the config. It
// overrides the single-node "cassandra" deployment's create:: with a
// multi-node topology. The storage processors are untouched and keep
// addressing host "cassandra" (cassandra_host), so node 0 deliberately
// keeps that name and acts as the sole seed; the rest of the ring is
// discovered via gossip.
//
// Caveat 1 (startup ordering): unlike Qdrant's Raft, Cassandra
// discourages bootstrapping multiple nodes simultaneously, and the
// engine has no depends_on/healthchecks - all nodes start at once and
// rely on restart:on-failure retries. For a small dev ring this usually
// settles after a few restart cycles, but it can be racy. If you hit
// schema/token disagreements, bring the nodes up staggered (seed first).
//
// Caveat 2 (data): forming the ring does not replicate data. The
// TrustGraph processors create keyspaces with replication_factor 1, so
// for now data still lives on one node. This is a scaffold for
// developing a replication strategy later.

{

    // Replication factor for keyspaces the consumers create. Defaults to the
    // ring size (default 2 peers + seed = 3); keep <= node count if you change
    // peers. Overrides the single-node default of 1 from cassandra.jsonnet.
    "cassandra-replication-factor":: 3,

    "cassandra" +: {

        // Memory settings (can be overridden by memory-profile)
        "memory-limit":: "1400M",
        "memory-reservation":: "1400M",
        "heap":: "700M",

        // Ring identity; must match across all nodes.
        "cluster-name":: "TrustGraph",

        // Number of peer nodes in addition to the seed node.
        // 2 peers -> a 3-node ring.
        "peers":: 2,

        create:: function(engine)

            local memLimit = self["memory-limit"];
            local memReserv = self["memory-reservation"];
            local heap = self["heap"];
            local clusterName = self["cluster-name"];
            local peers = self["peers"];

            // All nodes gossip-bootstrap through the seed (node 0).
            local seeds = "cassandra";

            // Build a single Cassandra node. Node 0 is the seed and keeps
            // the name "cassandra" so cassandra_host keeps resolving;
            // peers are cassandra-peer-N.
            local mkNode = function(index)

                local isSeed = index == 0;
                local name =
                    if isSeed then "cassandra"
                    else "cassandra-peer-%d" % index;

                local vol = engine.volume(name).with_size("20G");

                local container =
                    engine.container(name)
                        .with_image(images.cassandra)
                        .with_user(999)
                        .with_group(999)
                        .with_environment({
                            // No skip_wait_for_gossip_to_settle here: the
                            // single-node base sets it to 0 (skip the
                            // wait) for fast dev startup, but in a ring
                            // we want each node to wait for gossip to
                            // converge before proceeding, which is the
                            // default when the flag is absent.
                            JVM_OPTS: "-Xms%s -Xmx%s" % [heap, heap],
                            CASSANDRA_CLUSTER_NAME: clusterName,
                            CASSANDRA_SEEDS: seeds,
                        })
                        .with_limits("1.0", memLimit)
                        .with_reservations("0.5", memReserv)
                        .with_volume_mount(vol, "/var/lib/cassandra");

                local containerSet = engine.containers(name, [ container ]);

                // Internal-only service. 9042 is the CQL client port;
                // 7000 is the inter-node gossip channel and must stay
                // internal.
                local service =
                    engine.internalService(name, containerSet)
                    .with_port(9042, 9042, "cql")
                    .with_port(7000, 7000, "gossip");

                [ vol, containerSet, service ];

            local nodes = std.flattenArrays([
                mkNode(i)
                for i in std.range(0, peers)
            ]);

            engine.resources(nodes)

    },

}
