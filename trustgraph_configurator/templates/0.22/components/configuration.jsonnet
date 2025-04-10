local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

local prompts = import "prompts/mixtral.jsonnet";
local default_prompts = import "prompts/default-prompts.jsonnet";

{

    prompts:: default_prompts,
    tools:: [],

    local flow(x) = "persistent://tg/flow/" + x,
    local request(x) = "non-persistent://tg/request/" + x,
    local response(x) = "non-persistent://tg/response/" + x,

    local flow_classes = std.manifestJsonMinified({
        default: {
            "flow": {
                "pdf-decoder:{id}": {
                    input: flow("document-load:{id}"),
                    output: flow("text-document-load:{id}"),
                },
                "chunker:{id}": {
                    input: flow("text-document-load:{id}"),
                    output: flow("chunk-load:{id}"),
                },
                "kg-extract-definitions:{id}": {
                    input: flow("chunk-load:{id}"),
                    triples: flow("triples-store:{id}"),
                    "entity-contexts": flow("entity-contexts-load:{id}"),
                    "prompt-request": request("prompt:{class}"),
                    "prompt-response": response("prompt:{class}"),
                },
                "kg-extract-relationships:{id}": {
                    input: flow("chunk-load:{id}"),
                    triples: flow("triples-store:{id}"),
                    "prompt-request": request("prompt:{class}"),
                    "prompt-response": response("prompt:{class}"),
                },
                "graph-embeddings:{id}": {
                    input: flow("entity-contexts-load:{id}"),
                    output: flow("graph-embeddings-store:{id}"),
                    "embeddings-request": request("embeddings:{class}"),
                    "embeddings-response": response("embeddings:{class}"),
                },
                "document-embeddings:{id}": {
                    input: flow("chunk-load:{id}"),
                    output: flow("document-embeddings-store:{id}"),
                    "embeddings-request": request("embeddings:{class}"),
                    "embeddings-response": response("embeddings:{class}"),
                },
                "triples-write:{id}": {
                    input: flow("triples-store"),
                },
                "ge-write:{id}": {
                    input: flow("graph-embeddings-store"),
                },
                "de-write:{id}": {
                    input: flow("document-embeddings-store"),
                },
            },
            "class": {
                "embeddings:{class}": {
                    request: request("embeddings"),
                    response: response("embeddings"),
                },
                "graph-rag:{class}": {
                    request: request("graph-rag"),
                    response: response("graph-rag"),
                    "embeddings-request": request("embeddings"),
                    "embeddings-response": response("embeddings"),
                    "prompt-request": request("prompt"),
                    "prompt-response": response("prompt"),
                    "graph-embeddings-request": request("graph-embeddings"),
                    "graph-embeddings-response": response("graph-embeddings"),
                    "triples-request": request("triples"),
                    "triples-response": response("triples"),
                },
                "triples-query:{class}": {
                    request: request("triples"),
                    response: response("triples"),
                },
                "ge-query:{class}": {
                    request: request("graph-embeddings"),
                    response: response("graph-embeddings"),
                },
                "de-query:{class}": {
                    request: request("document-embeddings"),
                    response: response("document-embeddings"),
                },
                "prompt:{class}": {
                    request: request("prompt"),
                    response: response("prompt"),
                    "text-completion-request": request("text-completion"),
                    "text-completion-response": response("text-completion"),
                },
                "prompt-rag:{class}": {
                    request: request("prompt-rag"),
                    response: response("prompt-rag"),
                    "text-completion-request": request("text-completion-rag"),
                    "text-completion-response": response("text-completion-rag"),
                },
                "metering:{class}": {
                    input: response("text-completion"),
                },
                "text-completion:{class}": {
                    input: request("text-completion"),
                    output: response("text-completion"),
                },
                "text-completion-rag:{class}": {
                    input: request("text-completion-rag"),
                    output: response("text-completion-rag"),
                },
                "metering-rag:{class}": {
                    input: response("text-completion-rag"),
                },
            }
        }
    }),

    local configuration = std.manifestJsonMinified({
        prompt: {
            "system": $["prompts"]["system-template"],
            "template-index": std.objectFieldsAll($.prompts.templates),
        } + {
            ["template." + p.key]: p.value
            for p in std.objectKeysValuesAll($.prompts.templates)
        },
        agent: {
            "tool-index": [t.id for t in $.tools],
        } + {
            ["tool." + p.id]: p
            for p in $.tools
        }
    } + {
        "flow-classes": flow_definitions,
        "flows": {
        },
    }),

    "init-trustgraph" +: {
    
        create:: function(engine)

            local container =
                engine.container("init-trustgraph")
                    .with_image(images.trustgraph_flow)
                    .with_command(
                        [
                            "tg-init-pulsar",
                            "-p",
                            url.pulsar_admin,
                            "--config",
                            configuration,
                        ]
                    )
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "init-trustgraph", [ container ]
            );

            engine.resources([
                containerSet,
            ])

    },

} + default_prompts

