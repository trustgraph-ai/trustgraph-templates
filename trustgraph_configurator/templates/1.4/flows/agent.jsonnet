local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response = helpers.request_response;

{
    "interfaces": {
        "agent": request_response("agent:{id}"),
        "mcp-tool": request_response("mcp-tool:{class}"),
    },
    "parameters": {
    },
    "flow": {
        "agent-manager:{id}": {
            request: request("agent:{id}"),
            next: request("agent:{id}"),
            response: response("agent:{id}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
            "prompt-request": request("prompt:{class}"),
            "prompt-response": response("prompt:{class}"),
            "mcp-tool-request": request("mcp-tool:{class}"),
            "mcp-tool-response": response("mcp-tool:{class}"),
            "graph-rag-request": request("graph-rag:{class}"),
            "graph-rag-response": response("graph-rag:{class}"),
            "structured-query-request": request("structured-query:{class}"),
            "structured-query-response": response("structured-query:{class}"),
        },
    },
    "class": {
        "mcp-tool:{class}": {
            request: request("mcp-tool:{class}"),
            response: response("mcp-tool:{class}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
        },
    }
}