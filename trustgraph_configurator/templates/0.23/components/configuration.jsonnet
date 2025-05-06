local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

local prompts = import "prompts/mixtral.jsonnet";
local default_prompts = import "prompts/default-prompts.jsonnet";

local token_costs = import "values/token-costs.jsonnet";

{

    prompts:: default_prompts,
    tools:: [],

    local flow(x) = "persistent://tg/flow/" + x,
    local request(x) = "non-persistent://tg/request/" + x,
    local response(x) = "non-persistent://tg/response/" + x,
    local request_response(x) = {
        request: request(x),
        response: response(x),
    },

    "interface-descriptions":: {
        "document-load": {
            "description": "Document loader",
            "kind": "send",
            "visible": true,
        },
        "text-load": {
            "description": "Text document loader",
            "kind": "send",
            "visible": true,
        },
        "entity-contexts-load": {
            "description": "Entity contexts loader",
            "kind": "send",
        },
        "triples-store": {
            "description": "Triples loader",
            "kind": "send",
        },
        "graph-embeddings-store": {
            "description": "Graph embeddings loader",
            "kind": "send",
        },
        "document-embeddings-store": {
            "description": "Document embeddings loader",
            "kind": "send",
        },
        "graph-rag": {
            "description": "GraphRAG service",
            "kind": "request-response",
        },
        "document-rag": {
            "description": "ChunkRAG service",
            "kind": "request-response",
        },
        "triples": {
            "description": "Triples query service",
            "kind": "request-response",
        },
        "graph-embeddings": {
            "description": "Graph embeddings service",
            "kind": "request-response",
        },
        "document-embeddings": {
            "description": "Document embeddings service",
            "kind": "request-response",
        },
        "prompt": {
            "description": "Prompt service",
            "kind": "request-response",
        },
        "agent": {
            "description": "Agent service",
            "kind": "request-response",
        },
        "text-completion": {
            "description": "Text completion service",
            "kind": "request-response",
        },
    },

    "flow-classes":: {
        default: {
            "description": "Default flow class, supports GraphRAG and document RAG",
            "interfaces": {
                "document-load": flow("document-load:{id}"),
                "text-load": flow("text-document-load:{id}"),
                "entity-contexts-load": flow("entity-contexts-load:{id}"),
                "triples-store": flow("triples-store:{id}"),
                "graph-embeddings-store": flow("graph-embeddings-store:{id}"),
                "document-embeddings-store": flow("document-embeddings-store:{id}"),
                "graph-rag": request_response("graph-rag:{class}"),
                "document-rag": request_response("document-rag:{class}"),
                "triples": request_response("triples:{class}"),
                "graph-embeddings": request_response("graph-embeddings:{class}"),
                "embeddings": request_response("embeddings:{class}"),
                "document-embeddings": request_response("document-embeddings:{class}"),
                "prompt": request_response("prompt:{class}"),
                "agent": request_response("agent:{id}"),
                "text-completion": request_response("text-completion:{class}"),
            },
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

    local interfaces = function(classes, name, id)
        local intf = classes[name].interfaces;
        {
            [p.key]:
            if std.isString(p.value) then
                local i = std.strReplace(p.value, "{class}", name);
                local i2 = std.strReplace(i, "{id}", id);
                i2
            else
                {
                    [q.key]:
                        local i = std.strReplace(q.value, "{class}", name);
                        local i2 = std.strReplace(i, "{id}", id);
                        i2
                    for q in std.objectKeysValuesAll(p.value)
                }
            for p in std.objectKeysValuesAll(intf)
        },

    local default_flow_id = "0000",
    local default_flow_class = "default",

    // Temporary hackery
    local flow_array =
        class_processors($["flow-classes"], default_flow_class) +
        flow_processors($["flow-classes"], default_flow_class,
            default_flow_id),

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

    local default_flow_interfaces = interfaces(
        $["flow-classes"], default_flow_class, default_flow_id
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
        "interface-descriptions": $["interface-descriptions"],
        "flows": {
            [default_flow_id]: {
                "description": "Default processing flow",
                "class-name": "default",
                "interfaces": default_flow_interfaces,
            },
        },
        "flows-active": flows,
        "token-costs": token_costs,
    }),

    "init-trustgraph" +: {
    
        create:: function(engine)

            local container =
                engine.container("init-trustgraph")
                    .with_image(images.trustgraph_flow)
                    .with_command(
                        [
                            "tg-init-trustgraph",
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

