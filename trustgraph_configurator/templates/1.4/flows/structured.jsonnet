local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response = helpers.request_response;

{
    "interfaces": {
        "embeddings": request_response("embeddings:{class}"),
        "prompt": request_response("prompt:{class}"),
        "text-completion": request_response("text-completion:{class}"),
        "objects-store": flow("objects-store:{id}"),
        "objects": request_response("objects:{class}"),
        "nlp-query": request_response("nlp-query:{class}"),
        "structured-query": request_response("structured-query:{class}"),
        "structured-diag": request_response("structured-diag:{class}"),
    },
    "parameters": {
        "model": "llm-model",
    },
    "flow": {
        "kg-extract-objects:{id}": {
            input: flow("chunk-load:{id}"),
            output: flow("objects-store:{id}"),
            "entity-contexts": flow("entity-contexts-load:{id}"),
            "prompt-request": request("prompt:{class}"),
            "prompt-response": response("prompt:{class}"),
        },
        "objects-write:{id}": {
            input: flow("objects-store:{id}"),
        },
    },
    "class": {
        "objects-query:{class}": {
            request: request("objects:{class}"),
            response: response("objects:{class}"),
        },
        "nlp-query:{class}": {
            request: request("nlp-query:{class}"),
            response: response("nlp-query:{class}"),
            "prompt-request": request("prompt-rag:{class}"),
            "prompt-response": response("prompt-rag:{class}"),
        },
        "structured-query:{class}": {
            request: request("structured-query:{class}"),
            response: response("structured-query:{class}"),
            "nlp-query-request": request("nlp-query:{class}"),
            "nlp-query-response": response("nlp-query:{class}"),
            "objects-query-request": request("objects:{class}"),
            "objects-query-response": response("objects:{class}"),
        },
        "structured-diag:{class}": {
            request: request("structured-diag:{class}"),
            response: response("structured-diag:{class}"),
            "prompt-request": request("prompt:{class}"),
            "prompt-response": response("prompt:{class}"),
        },
        "embeddings:{class}": {
            request: request("embeddings:{class}"),
            response: response("embeddings:{class}"),
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