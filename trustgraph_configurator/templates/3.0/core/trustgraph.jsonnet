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
local erp_action = import "action/erp-finance.jsonnet";
local joke_action = import "action/joke.jsonnet";
local redact_action = import "action/redact.jsonnet";
local web_action = import "action/web.jsonnet";

{

    with:: function(key, value)
        self + {
            ["trustgraph-" + key]:: value,
        },

    parameters +:: {
        "log-level":: "INFO",
    },

} + control + ingest + rag + api_gateway + docling_decoder
  + ui + config

  // FIXME: These are action services, the ERP one provides test data.  These
  // are included by default now, will be removed for release, likely
  + erp_action + joke_action + redact_action + web_action

