local images = import "values/images.jsonnet";
local cassandra = import "cassandra.jsonnet";

// Self-hosted single-node Cassandra. List as the "cassandra" component to
// deploy it; consumers then talk to host "cassandra" with no auth. Mutually
// exclusive with cassandra-external (managed/secured cluster) - import one.
// cassandra-cluster overrides this single node with a multi-node ring.

cassandra + {

    "cassandra" +: {

        // Memory settings (can be overridden by memory-profile)
        "memory-limit":: "1400M",
        "memory-reservation":: "1400M",
        "heap":: "700M",

        create:: function(engine)

            // External Cassandra also selected (creds via env secrets): deploy
            // nothing, external wins. Consumers read CASSANDRA_HOST etc.
            if std.length($["cassandra-secrets"]) > 0 then
                engine.resources([])
            else

            // Capture memory settings into locals
            local memLimit = self["memory-limit"];
            local memReserv = self["memory-reservation"];
            local heap = self["heap"];

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
