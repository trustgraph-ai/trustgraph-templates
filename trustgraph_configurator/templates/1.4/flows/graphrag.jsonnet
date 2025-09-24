local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response = helpers.request_response;

{
    "interfaces": {
        "entity-contexts-load": flow("entity-contexts-load:{id}"),
        "triples-store": flow("triples-store:{id}"),
        "graph-embeddings-store": flow("graph-embeddings-store:{id}"),
        "graph-rag": request_response("graph-rag:{class}"),
        "triples": request_response("triples:{class}"),
        "graph-embeddings": request_response("graph-embeddings:{class}"),
        "embeddings": request_response("embeddings:{class}"),
        "prompt": request_response("prompt:{class}"),
        "text-completion": request_response("text-completion:{class}"),
    },
    "parameters": {
        "model": "llm-model",
    },
    "flow": {
        "graph-embeddings:{id}": {
            input: flow("entity-contexts-load:{id}"),
            output: flow("graph-embeddings-store:{id}"),
            "embeddings-request": request("embeddings:{class}"),
            "embeddings-response": response("embeddings:{class}"),
        },
        "triples-write:{id}": {
            input: flow("triples-store:{id}"),
        },
        "ge-write:{id}": {
            input: flow("graph-embeddings-store:{id}"),
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
        "triples-query:{class}": {
            request: request("triples:{class}"),
            response: response("triples:{class}"),
        },
        "ge-query:{class}": {
            request: request("graph-embeddings:{class}"),
            response: response("graph-embeddings:{class}"),
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
            model: "{model}",
        },
        "text-completion-rag:{class}": {
            request: request("text-completion-rag:{class}"),
            response: response("text-completion-rag:{class}"),
            model: "{model}",
        },
        "metering:{class}": {
            input: response("text-completion:{class}"),
        },
        "metering-rag:{class}": {
            input: response("text-completion-rag:{class}"),
        },
    }
}