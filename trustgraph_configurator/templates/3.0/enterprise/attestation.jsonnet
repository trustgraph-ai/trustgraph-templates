
// Enterprise feature, relies on Enterprise container.  Adds attestation
// engine to the RAG processor group, and adds attestation engine to the
// flows in the agent block

local images = import "values/images.jsonnet";
local attestation = import "flows/attestation.jsonnet";

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

    // Add attestation engine to the flow blueprints
    "flow-blueprints" +:: {
        "flow-blocks" +:: {
            "agent" +: attestation,
        }
    },

}
