// Shared MCP (Model Context Protocol) tool service module
// Provides MCP tool execution capabilities for agents
// Import this module in any flow that requires MCP tool integration

local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;

{
    // Interfaces exposed by MCP service
    "interfaces" +: {
        "mcp-tool": request_response_if("mcp-tool:{workspace}:{id}"),
    },

    "parameters" +: {
    },

    // Flow-level processor for MCP tool execution
    "flow" +: {
        "mcp-tool:{id}": {
            topics: {
                request: request("mcp-tool:{workspace}:{id}"),
                response: response("mcp-tool:{workspace}:{id}"),
                "text-completion-request": request("text-completion:{workspace}:{id}"),
                "text-completion-response": response("text-completion:{workspace}:{id}"),
            },
        },
    },

    "blueprint" +: {
    },
}
