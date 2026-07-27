local images = import "values/images.jsonnet";
local secrets = import "cassandra-secrets.jsonnet";

// Distributed (multi-node) Cassandra: N nodes forming a gossip ring
// behind a single headless service.
//
// Slots in like a memory profile: include AFTER the cassandra-backed
// store (triple-store-cassandra / row-store-cassandra) in the config. It
// overrides the single-node "cassandra" deployment's create:: with a
// multi-node topology. Consumers address host "cassandra" which, on K8s,
// is a headless service that resolves to all node pod IPs; on Compose
// it resolves to node 0 (the container named "cassandra").
//
// On K8s each node sets hostname + subdomain so individual pods are
// addressable as <hostname>.cassandra (e.g. cassandra-peer-1.cassandra).
// CASSANDRA_SEEDS=cassandra resolves to any live node's pod IP, so the
// ring can bootstrap without a fixed seed ordering.
//
// Caveat (data): forming the ring does not replicate data. The
// TrustGraph processors create keyspaces with replication_factor 1, so
// for now data still lives on one node. This is a scaffold for
// developing a replication strategy later.

secrets + {

    // Number of peer nodes in addition to the seed node. 2 peers -> a
    // 3-node ring. Top-level (not inside "cassandra") so it can be set
    // from a config entry's parameters, alongside cassandra-replication-factor.
    "cassandra-peers":: 2,

    // Replication factor for keyspaces the consumers create. Defaults to the
    // ring size (default 2 peers + seed = 3); keep <= node count if you change
    // cassandra-peers. Overrides the single-node default of 1 from
    // cassandra.jsonnet.
    "cassandra-replication-factor":: 3,

    // Per-node memory, settable via the override component's parameters.
    // Declared independently from the single-node store (separate recipe);
    // they happen to match today but neither file depends on the other.
    parameters +:: {
        "cassandra-heap": "700M",
        "cassandra-memory-limit": "1400M",
        "cassandra-memory-reservation": "1400M",
    },

    "cassandra" +: {

        // Ring identity; must match across all nodes.
        "cluster-name":: "TrustGraph",

        create:: function(engine)

            local pars = $.parameters;

            local memLimit = pars["cassandra-memory-limit"];
            local memReserv = pars["cassandra-memory-reservation"];
            local heap = pars["cassandra-heap"];
            local clusterName = self["cluster-name"];
            local peers = $["cassandra-peers"];

            local nodeName = function(index)
                if index == 0 then "cassandra"
                else "cassandra-peer-%d" % index;

            local nodeFqdn = function(index)
                "%s.cassandra.trustgraph.svc.cluster.local" %
                    nodeName(index);

            // Two fixed seeds by FQDN so every pod contacts the same
            // deterministic set. Using the bare headless service name
            // resolves to all pod IPs and causes split-brain when pods
            // race during bootstrap.
            local seedCount = std.min(2, peers + 1);
            local seeds = std.join(",", [
                nodeFqdn(i) for i in std.range(0, seedCount - 1)
            ]);

            local mkNode = function(index)

                local name = nodeName(index);

                local vol = engine.volume(name).with_size("20G");

                local container =
                    engine.container(name)
                        .with_image(images.cassandra)
                        .with_user(999)
                        .with_group(999)
                        .with_membership("cassandra")
                        .with_hostname(name)
                        .with_subdomain("cassandra")
                        .with_environment({
                            JVM_OPTS: "-Xms%s -Xmx%s" % [heap, heap],
                            CASSANDRA_CLUSTER_NAME: clusterName,
                            CASSANDRA_SEEDS: seeds,
                        })
                        .with_limits("1.0", memLimit)
                        .with_reservations("0.5", memReserv)
                        .with_volume_mount(vol, "/var/lib/cassandra");

                local containerSet = engine.containers(name, [ container ]);

                [ vol, containerSet ];

            local memberNames = [
                nodeName(i)
                for i in std.range(0, peers)
            ];

            local nodes = std.flattenArrays([
                mkNode(i)
                for i in std.range(0, peers)
            ]);

            local svc =
                engine.headlessService("cassandra", "cassandra", memberNames)
                .with_publish_not_ready_addresses()
                .with_port(9042, 9042, "cql")
                .with_port(7000, 7000, "gossip");

            engine.resources(nodes + [svc])

    },

}
