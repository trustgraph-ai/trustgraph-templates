// Keyword index (SQLite FTS5) - sparse/BM25 retrieval for Document-RAG.
// Deploys the kw-index processor, which consumes chunks off the ingestion
// stream and answers BM25 keyword queries. Ingest and query live in one
// service because the FTS5 index is a single local file (on the volume
// below). Including this component also flips Document-RAG to hybrid
// retrieval (vector + keyword fused by reciprocal rank fusion); override
// document-rag-retrieval-mode to choose another mode.

local images = import "values/images.jsonnet";

{

    parameters +:: {
        "document-rag-retrieval-mode": "hybrid",
        "keyword-index-concurrency": 1,
        "keyword-index-cpu-limit": "0.5",
        "keyword-index-cpu-reservation": "0.1",
        "keyword-index-memory-limit": "128M",
        "keyword-index-memory-reservation": "128M",
    },

    local logLevel = $.parameters["log-level"],

    "keyword-index" +: {

        local pars = $.parameters,

        local kwIndexConc = pars["keyword-index-concurrency"],
        local cpuLimit = pars["keyword-index-cpu-limit"],
        local cpuReservation = pars["keyword-index-cpu-reservation"],
        local memoryLimit = pars["keyword-index-memory-limit"],
        local memoryReservation = pars["keyword-index-memory-reservation"],

        create:: function(engine)

            local cfgVol = engine.configVolume(
                "keyword-index-launch-cfg", "launch/keyword-index",
                {
                    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.storage.kw_index.fts5.Processor",
                                params: {
                                    id: "kw-index",
                                    concurrency: kwIndexConc,
                                    index_path: "/data/kw-index.db",
                                } + $["pub-sub-params"],
                            },
                        ]
                    })
                }
            );

            local dataVol = engine.volume("keyword-index").with_size("5G");

            local container =
                engine.container("keyword-index")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch.yaml"
                    ])
                    .with_volume_mount(cfgVol, "/etc/trustgraph/")
                    .with_volume_mount(dataVol, "/data")
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "keyword-index", [ container ]
            );

            local service =
                engine.internalService("keyword-index", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                dataVol,
                containerSet,
                service,
            ])

    }

}
