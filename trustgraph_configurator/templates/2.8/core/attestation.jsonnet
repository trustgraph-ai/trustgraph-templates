
// Enterprise feature, relies on Enterprise container

local images = import "values/images.jsonnet";

{

    parameters +:: {
        "attestation-concurrency": 1,
    },

    "rag" +: {
        "rag-image":: images.trustgraph_enterprise,
        "rag-extra-processors" +:: [
            {
                class: "trustgraph.attestation.service.Processor",
                params: {
                    id: "attestation-engine",
                    concurrency: $.parameters["attestation-concurrency"],
                } + $["pub-sub-params"],
            },
        ],
        "image-pull-secret":: "private-registry-credentials",
    },

}
