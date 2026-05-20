local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local cassandra_hosts = "cassandra";
local cassandra = import "backends/cassandra.jsonnet";

cassandra + {

    parameters +:: {
        "triples-cpu-limit": "0.5",
        "triples-cpu-reservation": "0.1",
        "triples-memory-limit": "512M",
        "triples-memory-reservation": "512M",
    },

    local logLevel = $.parameters["log-level"],

    "triples" +: {

        local pars = $.parameters,

        local cpuLimit = pars["triples-cpu-limit"],
        local cpuReservation = pars["triples-cpu-reservation"],
        local memoryLimit = pars["triples-memory-limit"],
        local memoryReservation = pars["triples-memory-reservation"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "triples-launch-cfg", "launch/triples",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.query.triples.cassandra.Processor",
                                params: {
                                    id: "triples-query",
                                    cassandra_host: cassandra_hosts,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.triples.cassandra.Processor",
                                params: {
                                    id: "triples-write",
                                    cassandra_host: cassandra_hosts,
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local container =
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

            local containerSet = engine.containers(
                "triples", [ container ]
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
