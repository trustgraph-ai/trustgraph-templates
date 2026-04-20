local images = import "values/images.jsonnet";
local models = import "parameters/embeddings-fastembed.jsonnet";

{

    parameters +:: {
        "embeddings-concurrency": 1,
        "embeddings-cpu-limit": "4.0",
        "embeddings-cpu-reservation": "0.5",
        "embeddings-memory-limit": "640M",
        "embeddings-memory-reservation": "640M",
    },

    "fastembed-models":: models,

    "embeddings-models" +:: $["fastembed-models"],

    local logLevel = $.parameters["log-level"],

    "embeddings" +: {

        local pars = $.parameters,

        local embeddingsConc = pars["embeddings-concurrency"],
        local cpuLimit = pars["embeddings-cpu-limit"],
        local cpuReservation = pars["embeddings-cpu-reservation"],
        local memoryLimit = pars["embeddings-memory-limit"],
        local memoryReservation = pars["embeddings-memory-reservation"],

        local embeds = "trustgraph.embeddings",
        local fastEmbedProc = "%s.fastembed.Processor" % embeds,
        local docEmbedProc = "%s.document_embeddings.Processor" % embeds,
        local graphEmbedProc = "%s.graph_embeddings.Processor" % embeds,
        local rowEmbedProc = "%s.row_embeddings.Processor" % embeds,

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "embeddings-launch-cfg", "launch/embeddings",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: fastEmbedProc,
                                params: {
                                    id: "embeddings",
                                    concurrency: embeddingsConc,
                                } + $["pub-sub-params"],
                            },
                            {
                                class: docEmbedProc,
                                params: {
                                    id: "document-embeddings",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: graphEmbedProc,
                                params: {
                                    id: "graph-embeddings",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: rowEmbedProc,
                                params: {
                                    id: "row-embeddings",
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
		}
            );

            local container =
                engine.container("embeddings")
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
                "embeddings", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

}
