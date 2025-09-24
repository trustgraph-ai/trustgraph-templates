local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response = helpers.request_response;

{
    "interfaces": {
        "document-load": flow("document-load:{id}"),
        "text-load": flow("text-document-load:{id}"),
        "embeddings": request_response("embeddings:{class}"),
    },
    "parameters": {
    },
    "flow": {
        "pdf-decoder:{id}": {
            input: flow("document-load:{id}"),
            output: flow("text-document-load:{id}"),
        },
        "chunker:{id}": {
            input: flow("text-document-load:{id}"),
            output: flow("chunk-load:{id}"),
        },
    },
    "class": {
        "embeddings:{class}": {
            request: request("embeddings:{class}"),
            response: response("embeddings:{class}"),
        },
    }
}