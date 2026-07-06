// Document decoder processor — turns uploaded files (PDF, etc.)
// into the text representation consumed by the ingest pipeline.

local images = import "values/images.jsonnet";

{

    parameters +:: {
        "document-decoder-cpu-limit": "0.5",
        "document-decoder-cpu-reservation": "0.1",
        "document-decoder-memory-limit": "1400M",
        "document-decoder-memory-reservation": "1400M",
        "document-decoder-replicas": 1,
    },

    local logLevel = $.parameters["log-level"],

    "document-decoder" +: {

        local pars = $.parameters,

        local cpuLimit = pars["document-decoder-cpu-limit"],
        local cpuReservation = pars["document-decoder-cpu-reservation"],
        local memoryLimit = pars["document-decoder-memory-limit"],
        local memoryReservation = pars["document-decoder-memory-reservation"],
        local replicas = pars["document-decoder-replicas"],

        create:: function(engine)

            local container =
                engine.container("document-decoder")
                    .with_image(images.trustgraph_docling)
                    .with_command([
                        "docling-decoder",
                    ] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            local containerSet = engine.containers(
                "document-decoder", [ container ]
            ).with_replicas(replicas);

            local service =
                engine.internalService("document-decoder", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                containerSet,
                service,
            ])

    },

}
