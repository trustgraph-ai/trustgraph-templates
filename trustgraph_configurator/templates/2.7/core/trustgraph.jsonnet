// Core TrustGraph assembly.
// Composes the always-on processor set (control plane, ingest, RAG,
// API gateway, MCP server, workbench UI, runtime config) into a
// single object that the platform renderers consume. Individual
// processor definitions live in sibling files in this directory.

local images = import "values/images.jsonnet";

local config  = import "../runtime-config/trustgraph-config.jsonnet";
local control = import "control.jsonnet";
local ingest = import "ingest.jsonnet";
local rag = import "rag.jsonnet";
local api_gateway = import "api-gateway.jsonnet";
local docling_decoder = import "docling-decoder.jsonnet";
local ui = import "../ui/trustgraph-ui.jsonnet";
local ddg = import "mcp/ddg-mcp-server.jsonnet";

{

    with:: function(key, value)
        self + {
            ["trustgraph-" + key]:: value,
        },

    parameters +:: {
        "log-level":: "INFO",
    },

} + control + ingest + rag + api_gateway + docling_decoder
  + ui + config + ddg

