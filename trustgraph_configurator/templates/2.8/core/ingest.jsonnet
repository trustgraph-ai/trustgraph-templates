// Document ingest pipeline: loaders and pre-processing that feed
// the extraction and embedding stages.

local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

{

    parameters +:: {
        "kg-extract-definitions-concurrency": 1,
        "kg-extract-ontology-concurrency": 1,
        "kg-extract-relationships-concurrency": 1,
        "kg-extract-rows-concurrency": 1,
        "prompt-concurrency": 1,
        "ingest-cpu-limit": "0.5",
        "ingest-cpu-reservation": "0.1",
        "ingest-memory-limit": "256M",
        "ingest-memory-reservation": "256M",
        "ingest-replicas": 1,
        "chunker-type": "recursive",
    },

    local logLevel = $.parameters["log-level"],

    "ingest" +: {

        local pars = $.parameters,

        local exDefinitionsConc =
            pars["kg-extract-definitions-concurrency"],
        local exOntologyConc =
            pars["kg-extract-ontology-concurrency"],
        local exRelationshipsConc =
            pars["kg-extract-relationships-concurrency"],
        local exRowsConc =
            pars["kg-extract-rows-concurrency"],
        local promptConcurrency =
            pars["prompt-concurrency"],
        local cpuLimit = pars["ingest-cpu-limit"],
        local cpuReservation = pars["ingest-cpu-reservation"],
        local memoryLimit = pars["ingest-memory-limit"],
        local memoryReservation = pars["ingest-memory-reservation"],
        local replicas = pars["ingest-replicas"],
        local chunkerType = pars["chunker-type"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "ingest-launch-cfg", "launch/ingest",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.chunking." + chunkerType + ".Processor",
                                params: {
                                    id: "chunker",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.extract.kg.definitions.Processor",
                                params:  {
                                    id: "kg-extract-definitions",
                                    concurrency: exDefinitionsConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.extract.kg.ontology.Processor",
                                params: {
                                    id: "kg-extract-ontology",
                                    concurrency: exOntologyConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.extract.kg.relationships.Processor",
                                params: {
                                    id: "kg-extract-relationships",
                                    concurrency: exRelationshipsConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.extract.kg.rows.Processor",
                                params: {
                                    id: "kg-extract-rows",
                                    concurrency: exRowsConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.prompt.template.Processor",
                                params: {
                                    id: "prompt",
                                    concurrency: promptConcurrency,
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local container =
                engine.container("ingest")
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
                "ingest", [ container ]
            ).with_replicas(replicas);

            local service =
                engine.internalService("ingest", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

}

