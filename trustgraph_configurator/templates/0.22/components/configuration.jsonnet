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

    "flow-classes":: {
        default: {
            "descrption": "Default flow class, supports GraphRAG and document RAG",
            "tags": ["document-rag", "graph-rag", "knowledge-extraction"],
            "flow": {
                "agent-manager:{id}": {
                    request: request("agent:{id}"),
                    next: request("agent:{id}"),
                    response: response("agent:{id}"),
                    "text-completion-request": request("text-completion:{class}"),
                    "text-completion-response": response("text-completion:{class}"),
                    "prompt-request": request("prompt:{class}"),
                    "prompt-response": response("prompt:{class}"),
                    "graph-rag-request": request("graph-rag:{class}"),
                    "graph-rag-response": response("graph-rag:{class}"),
                },
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
                    input: flow("triples-store:{id}"),
                },
                "ge-write:{id}": {
                    input: flow("graph-embeddings-store:{id}"),
                },
                "de-write:{id}": {
                    input: flow("document-embeddings-store:{id}"),
                },
            },
            "class": {
                "embeddings:{class}": {
                    request: request("embeddings:{class}"),
                    response: response("embeddings:{class}"),
                },
                "graph-rag:{class}": {
                    request: request("graph-rag:{class}"),
                    response: response("graph-rag:{class}"),
                    "embeddings-request": request("embeddings:{class}"),
                    "embeddings-response": response("embeddings:{class}"),
                    "prompt-request": request("prompt-rag:{class}"),
                    "prompt-response": response("prompt-rag:{class}"),
                    "graph-embeddings-request": request("graph-embeddings:{class}"),
                    "graph-embeddings-response": response("graph-embeddings:{class}"),
                    "triples-request": request("triples:{class}"),
                    "triples-response": response("triples:{class}"),
                },
                "document-rag:{class}": {
                    request: request("document-rag:{class}"),
                    response: response("document-rag:{class}"),
                    "embeddings-request": request("embeddings:{class}"),
                    "embeddings-response": response("embeddings:{class}"),
                    "prompt-request": request("prompt-rag:{class}"),
                    "prompt-response": response("prompt-rag:{class}"),
                    "document-embeddings-request": request("document-embeddings:{class}"),
                    "document-embeddings-response": response("document-embeddings:{class}"),
                },
                "triples-query:{class}": {
                    request: request("triples:{class}"),
                    response: response("triples:{class}"),
                },
                "ge-query:{class}": {
                    request: request("graph-embeddings:{class}"),
                    response: response("graph-embeddings:{class}"),
                },
                "de-query:{class}": {
                    request: request("document-embeddings:{class}"),
                    response: response("document-embeddings:{class}"),
                },
                "prompt:{class}": {
                    request: request("prompt:{class}"),
                    response: response("prompt:{class}"),
                    "text-completion-request": request("text-completion:{class}"),
                    "text-completion-response": response("text-completion:{class}"),
                },
                "prompt-rag:{class}": {
                    request: request("prompt-rag:{class}"),
                    response: response("prompt-rag:{class}"),
                    "text-completion-request": request("text-completion-rag:{class}"),
                    "text-completion-response": response("text-completion-rag:{class}"),
                },
                "text-completion:{class}": {
                    request: request("text-completion:{class}"),
                    response: response("text-completion:{class}"),
                },
                "text-completion-rag:{class}": {
                    request: request("text-completion-rag:{class}"),
                    response: response("text-completion-rag:{class}"),
                },
                "metering:{class}": {
                    input: response("text-completion:{class}"),
                },
                "metering-rag:{class}": {
                    input: response("text-completion-rag:{class}"),
                },
            }
        },
    },

    local class_processors = function(classes, name)
        [
            [
                local key = std.strReplace(p.key, "{class}", name);
                local parts = std.splitLimit(key, ":", 2);
                parts,
                {
                    [q.key]: std.strReplace(q.value, "{class}", name)
                    for q in std.objectKeysValuesAll(p.value)
                }
            ]
            for p in std.objectKeysValuesAll(classes[name].class)
        ],

    local flow_processors = function(classes, name, id)
        [
            [
                local key = std.strReplace(
                    std.strReplace(p.key, "{class}", name),
                    "{id}", id
                );
                local parts = std.splitLimit(key, ":", 2);
                parts,
                {
                    [q.key]: std.strReplace(
                        std.strReplace(q.value, "{class}", name),
                        "{id}", id
                    )
                    for q in std.objectKeysValuesAll(p.value)
                }
            ]
            for p in std.objectKeysValuesAll(classes[name].flow)
        ],

    local flow_id = "0000",

    // Temporary hackery
    local flow_array =
        class_processors($["flow-classes"], "default") +
        flow_processors($["flow-classes"], "default", flow_id),

    local flow_objects = std.map(
        function(item) {
            [item[0][0]] +: {
                [item[0][1]]: item[1]
            }
        },
        flow_array
    ),

    local flows = std.foldr(
        function(a, b) a + b,
        flow_objects,
        {}
    ),

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
        },
        "flow-classes": $["flow-classes"],
        "flows": {
            [flow_id]: {
                "description": "Default processing flow",
            },
        },
        "flows-active": flows,
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

