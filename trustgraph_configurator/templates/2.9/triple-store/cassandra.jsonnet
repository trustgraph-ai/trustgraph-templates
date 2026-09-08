local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

// Reads the Cassandra hooks ($["cassandra-env-secrets"] / -replication-factor)
// off the merged config; whichever Cassandra backend is listed supplies them.

{

    parameters +:: {
        "triples-query-concurrency": 3,
        "triples-write-concurrency": 1,
        "triples-cpu-limit": "0.5",
        "triples-cpu-reservation": "0.1",
        "triples-memory-limit": "512M",
        "triples-memory-reservation": "512M",
        "triples-replicas": 1,
    },

    local logLevel = $.parameters["log-level"],

    "triples" +: {

        local pars = $.parameters,

        local triplesQueryConc = pars["triples-query-concurrency"],
        local triplesWriteConc = pars["triples-write-concurrency"],
        local cpuLimit = pars["triples-cpu-limit"],
        local cpuReservation = pars["triples-cpu-reservation"],
        local memoryLimit = pars["triples-memory-limit"],
        local memoryReservation = pars["triples-memory-reservation"],
        local replicas = pars["triples-replicas"],

        create:: function(engine)

            // External Cassandra supplies host/creds via env secrets; in that
            // case omit cassandra_host (and replication factor) so the processor
            // reads CASSANDRA_HOST / CASSANDRA_REPLICATION_FACTOR from env.
            local cassandraSecrets = $["cassandra-env-secrets"](engine);
            local cassandraParams =
                if cassandraSecrets != null then {}
                else {
                    cassandra_host: "cassandra",
                    cassandra_replication_factor:
                        $["cassandra-replication-factor"],
                };

            local cfgVol = engine.configVolume(
                "triples-launch-cfg", "launch/triples",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.query.triples.cassandra.Processor",
                                params: {
                                    id: "triples-query",
                                    concurrency: triplesQueryConc,
                                } + cassandraParams + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.triples.cassandra.Processor",
                                params: {
                                    id: "triples-write",
                                    concurrency: triplesWriteConc,
                                } + cassandraParams + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local baseContainer =
                engine.container("triples")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch.yaml"
                    ])
                    .with_volume_mount(cfgVol, "/etc/trustgraph/")
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local container =
                if cassandraSecrets != null then
                    baseContainer.with_env_var_secrets(cassandraSecrets)
                else baseContainer;

            local containerSet = engine.containers(
                "triples", [ container ]
            ).with_replicas(replicas);

            local service =
                engine.internalService("triples", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ] + (if cassandraSecrets != null then [ cassandraSecrets ] else []))

    },

}
