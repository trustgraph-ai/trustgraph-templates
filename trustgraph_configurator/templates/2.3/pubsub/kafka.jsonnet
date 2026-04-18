local images = import "values/images.jsonnet";

// Kafka messaging fabric configuration.
// Single-node KRaft-mode broker (no Zookeeper), playing the role of
// Pulsar / RabbitMQ in the TrustGraph pubsub fabric.

{

    "pub-sub-params":: {
        pubsub_backend: "kafka",
        kafka_bootstrap_servers: "kafka:9092",
    },

    "pub-sub-args":: [
        "--pubsub-backend",
        "kafka",
        "--kafka-bootstrap-servers",
        "kafka:9092",
    ],

    "pub-sub-init-args":: [],

    "overview-dashboard"::
        importstr "grafana/dashboards/overview-dashboard-pulsar.json",

    "prometheus-config"::
        importstr "prometheus/prometheus-pulsar.yml",

    "kafka" +: {

        // Memory settings (can be overridden by memory-profile)
        "memory-limit":: "1024M",
        "memory-reservation":: "1024M",

        // CPU settings
        "cpu-limit":: "1",
        "cpu-reservation":: "0.1",

        // Any base64-encoded 22-char string. Override per deployment if
        // you need a stable cluster identity across restarts.
        "cluster-id":: "YXM7bGtkamFzZGFsc2Rhc2QK",

        create:: function(engine)

            local memoryLimit = self["memory-limit"];
            local memoryReservation = self["memory-reservation"];
            local clusterId = self["cluster-id"];

            // Kafka volume for persistent KRaft log data
            local volume = engine.volume("kafka").with_size("10G");

            local container =
                engine.container("kafka")
                    .with_image(images.kafka)
                    .with_limits(self["cpu-limit"], memoryLimit)
                    .with_reservations(self["cpu-reservation"], memoryReservation)
                    .with_volume_mount(volume, "/var/lib/kafka/data")
                    .with_environment({
                        "KAFKA_NODE_ID": "1",
                        "KAFKA_PROCESS_ROLES": "broker,controller",
                        "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP":
                            "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT",
                        "KAFKA_CONTROLLER_QUORUM_VOTERS": "1@localhost:9093",
                        "KAFKA_LISTENERS":
                            "PLAINTEXT://:9092,CONTROLLER://:9093",
                        "KAFKA_INTER_BROKER_LISTENER_NAME": "PLAINTEXT",
                        "KAFKA_CONTROLLER_LISTENER_NAMES": "CONTROLLER",
                        "KAFKA_LOG_DIRS": "/var/lib/kafka/data",
                        "CLUSTER_ID": clusterId,
                        "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR": "1",
                        "KAFKA_OFFSETS_TOPIC_NUM_PARTITIONS": "12",
                        "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR": "1",
                        "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR": "1",
                        "KAFKA_AUTO_CREATE_TOPICS_ENABLE": "true",
                        "KAFKA_MESSAGE_MAX_BYTES": "10485760",
                        "KAFKA_REPLICA_FETCH_MAX_BYTES": "10485760",
                    })
                    .with_port(9092, 9092, "kafka");

            local containerSet = engine.containers(
                "kafka", [ container ]
            );

            local service =
                engine.service(containerSet)
                .with_port(9092, 9092, "kafka");

            engine.resources([
                volume,
                containerSet,
                service,
            ])

    }

}
