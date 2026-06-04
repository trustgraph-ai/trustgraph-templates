local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

// Reads the Cassandra hooks ($["cassandra-env-secrets"] / -replication-factor)
// off the merged config; whichever Cassandra backend is listed supplies them.

{

    parameters +:: {
        "rows-cpu-limit": "0.5",
        "rows-cpu-reservation": "0.1",
        "rows-memory-limit": "512M",
        "rows-memory-reservation": "512M",
        "rows-replicas": 1,
    },

    local logLevel = $.parameters["log-level"],

    "rows" +: {

        local pars = $.parameters,

        local cpuLimit = pars["rows-cpu-limit"],
        local cpuReservation = pars["rows-cpu-reservation"],
        local memoryLimit = pars["rows-memory-limit"],
        local memoryReservation = pars["rows-memory-reservation"],
        local replicas = pars["rows-replicas"],

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
                "rows-launch-cfg", "launch/rows",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.query.rows.cassandra.Processor",
                                params: {
                                    id: "rows-query",
                                } + cassandraParams + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.rows.cassandra.Processor",
                                params: {
                                    id: "rows-write",
                                } + cassandraParams + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local baseContainer =
                engine.container("rows")
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
                "rows", [ container ]
            ).with_replicas(replicas);

            local service =
                engine.internalService("rows", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ] + (if cassandraSecrets != null then [ cassandraSecrets ] else []))

    },

}
