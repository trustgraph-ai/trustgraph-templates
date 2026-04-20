// Core TrustGraph assembly.
// Composes the always-on processor set (control plane, ingest, RAG,
// API gateway, MCP server, workbench UI, runtime config) into a
// single object that the platform renderers consume. Individual
// processor definitions live in sibling files in this directory.

local images = import "values/images.jsonnet";

local config_initialiser = import "configuration.jsonnet";
local config  = import "../runtime-config/trustgraph-config.jsonnet";
local control = import "control.jsonnet";
local ingest = import "ingest.jsonnet";
local rag = import "rag.jsonnet";
local api_gateway = import "api-gateway.jsonnet";
local mcp_server = import "mcp-server.jsonnet";
local document_decoder = import "document-decoder.jsonnet";
local workbench = import "../ui/workbench-ui.jsonnet";
local ddg = import "mcp/ddg-mcp-server.jsonnet";

{
    parameters +:: {
        "log-level":: "INFO",
    },

} + control + ingest + rag + api_gateway + mcp_server + document_decoder
  + workbench + config_initialiser + config + ddg

