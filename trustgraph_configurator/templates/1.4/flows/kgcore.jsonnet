local helpers = import "helpers.jsonnet";
local flow = helpers.flow;

{
    "interfaces": {
    },
    "parameters": {
    },
    "flow": {
        "kg-store:{id}": {
            "triples-input": flow("triples-store:{id}"),
            "graph-embeddings-input": flow("graph-embeddings-store:{id}"),
        },
    },
    "class": {
    }
}