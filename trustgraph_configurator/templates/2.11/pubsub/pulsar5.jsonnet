local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

// Pulsar 5 configuration using Oxia as the metadata store,
// replacing ZooKeeper.

{

    "pub-sub-params":: {
        pubsub_backend: "pulsar",
        pulsar_host: url.pulsar,
    },

    "pub-sub-admin-params":: {
        pulsar_admin_url: url.pulsar_admin,
    },

    "pub-sub-args":: [
        "--pubsub-backend",
        "pulsar",
        "--pulsar-host",
        url.pulsar,
    ],

    "pub-sub-init-args":: [
        "--pulsar-admin-url",
        url.pulsar_admin,
    ],

    "overview-dashboard"::
        importstr "grafana/dashboards/overview-dashboard-pulsar.json",

    "prometheus-config"::
        importstr "prometheus/prometheus-pulsar.yml",

    with_params:: function(pars)
        self + {
            "pulsar" +: std.foldl(
                function(obj, par) obj + { [par.key]:: par.value },
                std.objectKeysValues(pars),
                {}
            ),
        },

    "pulsar" +: {

        // Oxia memory settings (can be overridden by memory-profile)
        "oxia-memory-limit":: "512M",
        "oxia-memory-reservation":: "512M",

        // Bookie memory settings (can be overridden by memory-profile)
        "bookie-memory-limit":: "1024M",
        "bookie-memory-reservation":: "1024M",
        "bookie-heap":: "256m",
        "bookie-direct-memory":: "256m",

        // Broker memory settings (can be overridden by memory-profile)
        "broker-memory-limit":: "800M",
        "broker-memory-reservation":: "800M",
        "broker-heap":: "384m",
        "broker-direct-memory":: "384m",

        // Pulsar-init memory settings (can be overridden by memory-profile)
        "init-memory-limit":: "256M",
        "init-memory-reservation":: "256M",
        "init-heap":: "128m",
        "init-direct-memory":: "128m",

        create:: function(engine)

            local oxiaMemLimit = self["oxia-memory-limit"];
            local oxiaMemReserv = self["oxia-memory-reservation"];

            local bookieMemLimit = self["bookie-memory-limit"];
            local bookieMemReserv = self["bookie-memory-reservation"];
            local bookieHeap = self["bookie-heap"];
            local bookieDirect = self["bookie-direct-memory"];

            local brokerMemLimit = self["broker-memory-limit"];
            local brokerMemReserv = self["broker-memory-reservation"];
            local brokerHeap = self["broker-heap"];
            local brokerDirect = self["broker-direct-memory"];

            local initMemLimit = self["init-memory-limit"];
            local initMemReserv = self["init-memory-reservation"];
            local initHeap = self["init-heap"];
            local initDirect = self["init-direct-memory"];

            // Oxia volume
            local oxiaVolume = engine.volume("oxia").with_size("1G");

            // Oxia container
            local oxiaContainer =
                engine.container("oxia")
                    .with_image(images.oxia)
                    .with_command([
                        "oxia", "standalone",
                    ])
                    .with_limits("1", oxiaMemLimit)
                    .with_reservations("0.05", oxiaMemReserv)
                    .with_volume_mount(oxiaVolume, "/data")
                    .with_port(6648, 6648, "oxia");

            // Pulsar cluster init container
            local initContainer =
                engine.container("pulsar-init")
                    .with_image(images.pulsar5)
                    .with_command([
                        "bash",
                        "-c",
                        "until (echo > /dev/tcp/oxia/6648) >/dev/null 2>&1; do sleep 2; done && bin/pulsar initialize-cluster-metadata --cluster cluster-a --metadata-store oxia://oxia:6648/default --configuration-store oxia://oxia:6648/default --web-service-url http://pulsar:8080 --broker-service-url pulsar://pulsar:6650",
                    ])
                    .with_limits("1", initMemLimit)
                    .with_reservations("0.05", initMemReserv)
                    .with_environment({
                        "PULSAR_MEM": "-Xms%s -Xmx%s -XX:MaxDirectMemorySize=%s" % [
                            initHeap, initHeap, initDirect,
                        ],
                    });

            // Bookkeeper volume
            local bookieVolume = engine.volume("bookie").with_size("20G");

            // Bookkeeper container
            local bookieContainer =
                engine.container("bookie")
                    .with_image(images.pulsar5)
                    .with_command([
                        "bash",
                        "-c",
                        "until (echo > /dev/tcp/oxia/6648) >/dev/null 2>&1; do sleep 2; done && bin/apply-config-from-env.py conf/bookkeeper.conf && exec bin/pulsar bookie"
                    ])
                    .with_limits("1", bookieMemLimit)
                    .with_reservations("0.1", bookieMemReserv)
                    .with_user(0)
                    .with_group(1000)
                    .with_volume_mount(bookieVolume, "/pulsar/data")
                    .with_environment({
                        "clusterName": "cluster-a",
                        "metadataServiceUri": "metadata-store:oxia://oxia:6648/default",
                        "advertisedAddress": "bookie",
                        "BOOKIE_MEM": "-Xms%s -Xmx%s -XX:MaxDirectMemorySize=%s" % [
                            bookieHeap, bookieHeap, bookieDirect,
                        ],
                    })
                    .with_port(3181, 3181, "bookie");

            // Pulsar broker
            local brokerContainer =
                engine.container("pulsar")
                    .with_image(images.pulsar5)
                    .with_command([
                        "bash",
                        "-c",
                        "bin/apply-config-from-env.py conf/broker.conf && exec bin/pulsar broker"
                    ])
                    .with_limits("1", brokerMemLimit)
                    .with_reservations("0.1", brokerMemReserv)
                    .with_environment({
                        "metadataStoreUrl": "oxia://oxia:6648/default",
                        "clusterName": "cluster-a",
                        "managedLedgerDefaultEnsembleSize": "1",
                        "managedLedgerDefaultWriteQuorum": "1",
                        "managedLedgerDefaultAckQuorum": "1",
                        "advertisedAddress": "pulsar",
                        "advertisedListeners": "external:pulsar://pulsar:6650,localhost:pulsar://localhost:6650",
                        "PULSAR_MEM": "-Xms%s -Xmx%s -XX:MaxDirectMemorySize=%s" % [
                            brokerHeap, brokerHeap, brokerDirect,
                        ],
                        "exposeProducerLevelMetricsInPrometheus": "false",
                        "exposeConsumerLevelMetricsInPrometheus": "false",
                    })
                    .with_port(6650, 6650, "pulsar")
                    .with_port(8080, 8080, "admin");

            // Container sets
            local oxiaContainerSet = engine.containers(
                "oxia",
                [
                    oxiaContainer,
                ]
            );

            local initContainerSet = engine.containers(
                "init-pulsar",
                [
                    initContainer,
                ]
            );

            local bookieContainerSet = engine.containers(
                "bookie",
                [
                    bookieContainer,
                ]
            );

            local brokerContainerSet = engine.containers(
                "pulsar",
                [
                    brokerContainer,
                ]
            );

            // Oxia service
            local oxiaService =
                engine.internalService("oxia", oxiaContainerSet)
                .with_port(6648, 6648, "oxia");

            // Bookkeeper service
            local bookieService =
                engine.internalService("bookie", bookieContainerSet)
                .with_port(3181, 3181, "bookie");

            // Pulsar broker service
            local brokerService =
                engine.internalService("pulsar", brokerContainerSet)
                .with_port(6650, 6650, "pulsar")
                .with_port(8080, 8080, "admin");

            engine.resources([
                oxiaVolume,
                bookieVolume,
                oxiaContainerSet,
                initContainerSet,
                bookieContainerSet,
                brokerContainerSet,
                oxiaService,
                bookieService,
                brokerService,
            ])

    }

}
