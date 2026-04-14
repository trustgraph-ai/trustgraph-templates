local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local cassandra_hosts = "cassandra";
local cassandra = import "backends/cassandra.jsonnet";

cassandra + {

    parameters +:: {
        "rows-cpu-limit": "0.5",
        "rows-cpu-reservation": "0.1",
        "rows-memory-limit": "512M",
        "rows-memory-reservation": "512M",
    },

    local logLevel = $.parameters["log-level"],

    "rows" +: {

        local pars = $.parameters,

        local cpuLimit = pars["rows-cpu-limit"],
        local cpuReservation = pars["rows-cpu-reservation"],
        local memoryLimit = pars["rows-memory-limit"],
        local memoryReservation = pars["rows-memory-reservation"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "rows-launch-cfg", "launch/rows",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.query.rows.cassandra.Processor",
                                params: {
                                    id: "rows-query",
                                    cassandra_host: cassandra_hosts,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.rows.cassandra.Processor",
                                params: {
                                    id: "rows-write",
                                    cassandra_host: cassandra_hosts,
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local container =
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

            local containerSet = engine.containers(
                "rows", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    },

}
