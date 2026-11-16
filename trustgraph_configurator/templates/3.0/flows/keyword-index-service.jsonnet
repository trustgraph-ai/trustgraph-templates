// Shared keyword index service module
// Provides sparse (BM25) keyword search over document chunks
// Import this module in any flow that requires keyword retrieval

local helpers = import "helpers.jsonnet";
local flow = helpers.flow;
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

{
    // Interfaces exposed by keyword index service
    "interfaces" +: {
        "keyword-index": request_response_if("keyword-index:{workspace}:{id}"),
    },

    "parameters" +: {
    },

    // Flow-level processor for the keyword index: indexes chunks off the
    // same ingestion stream document-embeddings consumes, answers keyword
    // queries. Only bound when a kw-index processor is deployed; the entry
    // is inert otherwise.
    "flow" +: {
        "kw-index:{id}": {
            topics: {
                input: flow("chunk-load:{workspace}:{id}"),
                request: request("keyword-index:{workspace}:{id}"),
                response: response("keyword-index:{workspace}:{id}"),
            },
        },
    },

    "blueprint" +: {
    },
}
