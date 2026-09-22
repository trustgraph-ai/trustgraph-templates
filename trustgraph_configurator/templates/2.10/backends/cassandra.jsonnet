local images = import "values/images.jsonnet";
local secrets = import "cassandra-secrets.jsonnet";

// Self-hosted single-node Cassandra. List as the "cassandra" component to
// deploy it; consumers then talk to host "cassandra" with no auth. Mutually
// exclusive with cassandra-external (managed/secured cluster) - import one.
// cassandra-cluster overrides this single node with a multi-node ring.

secrets + {

    // Replication factor for keyspaces the consumers create. 1 for a single
    // node; cassandra-cluster raises it to the ring size. Consumers read this
    // in self-hosted mode and omit it in external mode (CASSANDRA_REPLICATION_
    // FACTOR env wins).
    "cassandra-replication-factor":: 1,

    // Per-node memory, settable via the override component's parameters.
    // Declared independently from cassandra-cluster (separate recipe).
    parameters +:: {
        "cassandra-heap": "700M",
        "cassandra-memory-limit": "1400M",
        "cassandra-memory-reservation": "1400M",
    },

    "cassandra" +: {

        create:: function(engine)

            // External Cassandra also selected (creds via env secrets): deploy
            // nothing, external wins. Consumers read CASSANDRA_HOST etc.
            if std.length($["cassandra-secrets"]) > 0 then
                engine.resources([])
            else

            local pars = $.parameters;
            local memLimit = pars["cassandra-memory-limit"];
            local memReserv = pars["cassandra-memory-reservation"];
            local heap = pars["cassandra-heap"];

            local vol = engine.volume("cassandra").with_size("20G");

            local container =
                engine.container("cassandra")
                    .with_image(images.cassandra)
                    .with_user(999)
                    .with_group(999)
                    .with_environment({
                        JVM_OPTS: "-Xms%s -Xmx%s -Dcassandra.skip_wait_for_gossip_to_settle=0" % [
                            heap, heap,
                        ],
                    })
                    .with_limits("1.0", memLimit)
                    .with_reservations("0.5", memReserv)
                    .with_port(9042, 9042, "cassandra")
                    .with_volume_mount(vol, "/var/lib/cassandra");

            local containerSet = engine.containers(
                "cassandra", [ container ]
            );

            local service =
                engine.internalService("cassandra", containerSet)
                .with_port(9042, 9042, "api");

            engine.resources([
                vol,
                containerSet,
                service,
            ])

    },

}
