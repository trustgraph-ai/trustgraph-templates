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
        "kg-extract-agent:{id}": {
            input: flow("chunk-load:{id}"),
            triples: flow("triples-store:{id}"),
            "entity-contexts": flow("entity-contexts-load:{id}"),
            "agent-request": request("agent:{id}"),
            "agent-response": response("agent:{id}"),
        },
    },
    "class": {
    }
}