
// This puts the default configuration together.  References many things,
// flow classes, a default flow, token costs, prompts, agent tools

local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

local prompts = import "prompts/mixtral.jsonnet";
local default_prompts = import "prompts/default-prompts.jsonnet";

local token_costs = import "values/token-costs.jsonnet";

local flow_classes = import "flows/flow-classes.jsonnet";

local configuration = {

    prompts:: default_prompts,

    tools:: [
        {
            id: "knowledge-extraction",
            name: "Knowledge extraction",
            description: "Takes a chunk of text and extracts knowledge in definition and relationship formats. The input is a text chunk",
            type: "prompt",
            template: "agent-kg-extract",
            arguments: [
                {
                    "name": "text",
                    "type": "string",
                    "description": "The text chunk",
                }
            ],
        },
        {
            id: "knowledge-query",
            name: "Knowledge query",
            description: "This tool queries a knowledge base that holds information about domain-specific information.  The question should be a natural language question.",
            type: "knowledge-query",
            collection: "default",
            arguments: [
                {
                    name: "question",
                    type: "string",
                    description: "A simple natural language question.",
                }
            ]
        },
        {
            id: "llm-completion",
            name: "LLM text completion",
            type: "text-completion",
            description: "This tool queries an LLM for non-domain-specific information.  The question should be a natural language question.",
            arguments: [
                {
                    name: "question",
                    type: "string",
                    description: "The question which should be asked of the LLM.",
                }
            ]
        }
    ],

    mcp:: {},

    "flow-classes":: flow_classes,

    // This defines standard 'interfaces'.  Different flow classes can
    // support different interfaces.  Interfaces are 'external' endpoints
    // into a processing chain.
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
        "objects-store": {
            "description": "Object store",
            "kind": "request-response",
        },
        "objects": {
            "description": "Object query service",
            "kind": "request-response",
        },
        "nlp-query": {
            "description": "NLP question to GraphQL service",
            "kind": "request-response",
        },
        "structured-query": {
            "description": "Structured query service",
            "kind": "request-response",
        },
    },

    configuration:: {

        create:: function(engine) {},

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

        local default_flow_id = "default",
        local default_flow_class = "everything",

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

        local flows_active = std.foldr(
            function(a, b) a + b,
            flow_objects,
            {}
        ),

        local default_flow_interfaces = interfaces(
            $["flow-classes"], default_flow_class, default_flow_id
        ),

        configuration:: {
            prompt: {
                "system": $["prompts"]["system-template"],
                "template-index": std.objectFieldsAll($.prompts.templates),
            } + {
                ["template." + p.key]: p.value
                for p in std.objectKeysValuesAll($.prompts.templates)
            },
            tool: {
                [p.id]: p
                for p in $.tools
            },
            mcp: $.mcp,
            "flow-classes": $["flow-classes"],
            "interface-descriptions": $["interface-descriptions"],
            "flows": {
                [default_flow_id]: {
                    "description": "Default processing flow",
                    "class-name": default_flow_class,
                    "interfaces": default_flow_interfaces,
                },
            },
            "flows-active": flows_active,
            "token-costs": token_costs,
            "parameter-types": {
                "llm-model": {
                  "type": "string",
                  "description": "LLM model to use",
                  "default": "gpt-4",
                  "enum": [
                      {
                          id: "gemini-2.5-pro",
                          description: "Gemini 2.5 Pro"
                      },
                      {
                          id: "gemini-2.5-flash",
                          description: "Gemini Flash"
                      },
                      {
                          id: "gemini-2.5-flash-lite",
                          description: "Gemini 2.5 Flash-Lite"
                      },
                  ],
                  "required": false
                },
            },
        },

    },

} + default_prompts;

configuration

