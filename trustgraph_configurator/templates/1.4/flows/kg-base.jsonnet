local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;

{
    "interfaces": {
    },
    "parameters": {
    },
    "flow": {
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
    },
    "class": {
    }
}