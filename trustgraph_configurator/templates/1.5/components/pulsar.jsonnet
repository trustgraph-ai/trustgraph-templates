local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local etcd = import "stores/etcd.jsonnet";

// This is a Pulsar configuration.  Non-standalone mode so we deploy
// individual components: bookkeeper, broker and zookeeper.
// 
// This also deploys the TrustGraph 'admin' container which initialises
// TrustGraph-specific namespaces etc.

{

    "pulsar" +: {

        create:: function(engine)

            // Pulsar cluster init container
            local initContainer =
                engine.container("pulsar-init")
                    .with_image(images.pulsar)
                    .with_command([
                        "bash",
                        "-c",
                        "sleep 10 && bin/pulsar initialize-cluster-metadata --cluster cluster-a --metadata-store etcd:http://etcd:2379 --configuration-metadata-store etcd:http://etcd:2379 --web-service-url http://pulsar:8080 --broker-service-url pulsar://pulsar:6650",
                    ])
                    .with_limits("1", "512M")
                    .with_reservations("0.05", "512M")
                    .with_environment({
                        "PULSAR_MEM": "-Xms256m -Xmx256m -XX:MaxDirectMemorySize=256m",
                    });


            // Bookkeeper volume
            local bookieVolume = engine.volume("bookie").with_size("20G");

            // Bookkeeper container
            local bookieContainer = 
                engine.container("bookie")
                    .with_image(images.pulsar)
                    .with_command([
                        "bash",
                        "-c",
                        "bin/apply-config-from-env.py conf/bookkeeper.conf && exec bin/pulsar bookie"
                        // false ^ causes this to be a 'failure' exit.
                    ])
                    .with_limits("1", "1024M")
                    .with_reservations("0.1", "1024M")
                    .with_user("0:1000")
                    .with_volume_mount(bookieVolume, "/pulsar/data/bookkeeper")
                    .with_environment({
                        "clusterName": "cluster-a",
                        "bookieId": "bookie",
                        "metadataServiceUri": "metadata-store:etcd:http://etcd:2379/ledgers",
                        "ledgerManagerType": "hierarchical",
                        "journalDirectory": "data/bookkeeper/journal",
                        "ledgerDirectories": "data/bookkeeper/ledgers",
                        "advertisedAddress": "bookie",
                        "BOOKIE_MEM": "-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m",
                    })
                    .with_port(3181, 3181, "bookie");

            // Pulsar broker, stateless (uses etcd and Bookkeeper for state)
            local brokerContainer = 
                engine.container("pulsar")
                    .with_image(images.pulsar)
                    .with_command([
                        "bash",
                        "-c",
                        "bin/apply-config-from-env.py conf/broker.conf && exec bin/pulsar broker"
                    ])
                    .with_limits("1", "800M")
                    .with_reservations("0.1", "800M")
                    .with_environment({
                        "metadataStoreUrl": "etcd:http://etcd:2379",
                        "configurationMetadataStoreUrl": "etcd:http://etcd:2379",
                        "bookkeeperMetadataServiceUri": "metadata-store:etcd:http://etcd:2379/ledgers",
                        "clusterName": "cluster-a",
                        "managedLedgerDefaultEnsembleSize": "1",
                        "managedLedgerDefaultWriteQuorum": "1",
                        "managedLedgerDefaultAckQuorum": "1",
                        "advertisedAddress": "pulsar",
                        "advertisedListeners": "external:pulsar://pulsar:6650,localhost:pulsar://localhost:6650",
                        "PULSAR_MEM": "-Xms512m -Xmx512m -XX:MaxDirectMemorySize=256m",
                    })
                    .with_port(6650, 6650, "pulsar")
                    .with_port(8080, 8080, "admin");

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

            // Bookkeeper service
            local bookieService =
                engine.service(bookieContainerSet)
                .with_port(3181, 3181, "bookie");

            // Pulsar broker service
            local brokerService =
                engine.service(brokerContainerSet)
                .with_port(6650, 6650, "pulsar")
                .with_port(8080, 8080, "admin");

            engine.resources([
                bookieVolume,
                initContainerSet,
                bookieContainerSet,
                brokerContainerSet,
                bookieService,
                brokerService,
            ])

    }

} + etcd



