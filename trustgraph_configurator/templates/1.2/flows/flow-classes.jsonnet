local flow(x) = "persistent://tg/flow/" + x;
local request(x) = "non-persistent://tg/request/" + x;
local response(x) = "non-persistent://tg/response/" + x;
local request_response(x) = {
  request: request(x),
  response: response(x),
};

local graphrag_part = {
    "interfaces" +: {
        "entity-contexts-load": flow("entity-contexts-load:{id}"),
        "triples-store": flow("triples-store:{id}"),
        "graph-embeddings-store": flow("graph-embeddings-store:{id}"),
        "graph-rag": request_response("graph-rag:{class}"),
        "triples": request_response("triples:{class}"),
        "graph-embeddings": request_response("graph-embeddings:{class}"),
        "embeddings": request_response("embeddings:{class}"),
        "prompt": request_response("prompt:{class}"),
        "mcp-tool": request_response("mtp-tool:{class}"),
        "text-completion": request_response("text-completion:{class}"),
    },
    "flow" +: {
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
        "graph-embeddings:{id}": {
            input: flow("entity-contexts-load:{id}"),
            output: flow("graph-embeddings-store:{id}"),
            "embeddings-request": request("embeddings:{class}"),
            "embeddings-response": response("embeddings:{class}"),
        },
        "triples-write:{id}": {
            input: flow("triples-store:{id}"),
        },
        "ge-write:{id}": {
            input: flow("graph-embeddings-store:{id}"),
        },
    },
    "class" +: {
        "embeddings:{class}": {
            request: request("embeddings:{class}"),
            response: response("embeddings:{class}"),
        },
        "graph-rag:{class}": {
            request: request("graph-rag:{class}"),
            response: response("graph-rag:{class}"),
            "embeddings-request": request("embeddings:{class}"),
            "embeddings-response": response("embeddings:{class}"),
            "prompt-request": request("prompt-rag:{class}"),
            "prompt-response": response("prompt-rag:{class}"),
            "graph-embeddings-request": request("graph-embeddings:{class}"),
            "graph-embeddings-response": response("graph-embeddings:{class}"),
            "triples-request": request("triples:{class}"),
            "triples-response": response("triples:{class}"),
        },
        "triples-query:{class}": {
            request: request("triples:{class}"),
            response: response("triples:{class}"),
        },
        "ge-query:{class}": {
            request: request("graph-embeddings:{class}"),
            response: response("graph-embeddings:{class}"),
        },
        "prompt:{class}": {
            request: request("prompt:{class}"),
            response: response("prompt:{class}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
        },
        "prompt-rag:{class}": {
            request: request("prompt-rag:{class}"),
            response: response("prompt-rag:{class}"),
            "text-completion-request": request("text-completion-rag:{class}"),
            "text-completion-response": response("text-completion-rag:{class}"),
        },
        "mcp-tool:{class}": {
            request: request("mcp-tool:{class}"),
            response: response("mcp-tool:{class}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
        },
        "text-completion:{class}": {
            request: request("text-completion:{class}"),
            response: response("text-completion:{class}"),
        },
        "text-completion-rag:{class}": {
            request: request("text-completion-rag:{class}"),
            response: response("text-completion-rag:{class}"),
        },
        "metering:{class}": {
            input: response("text-completion:{class}"),
        },
        "metering-rag:{class}": {
            input: response("text-completion-rag:{class}"),
        },
    }
};

local documentrag_part = {
    "interfaces" +: {
        "document-embeddings-store": flow("document-embeddings-store:{id}"),
        "document-rag": request_response("document-rag:{class}"),
        "embeddings": request_response("embeddings:{class}"),
        "document-embeddings": request_response("document-embeddings:{class}"),
        "prompt": request_response("prompt:{class}"),
        "mcp-tool": request_response("mcp-tool:{class}"),
        "text-completion": request_response("text-completion:{class}"),
    },
    "flow" +: {
        "document-embeddings:{id}": {
            input: flow("chunk-load:{id}"),
            output: flow("document-embeddings-store:{id}"),
            "embeddings-request": request("embeddings:{class}"),
            "embeddings-response": response("embeddings:{class}"),
        },
        "de-write:{id}": {
            input: flow("document-embeddings-store:{id}"),
        },
    },
    "class" +: {
        "embeddings:{class}": {
            request: request("embeddings:{class}"),
            response: response("embeddings:{class}"),
        },
        "document-rag:{class}": {
            request: request("document-rag:{class}"),
            response: response("document-rag:{class}"),
            "embeddings-request": request("embeddings:{class}"),
            "embeddings-response": response("embeddings:{class}"),
            "prompt-request": request("prompt-rag:{class}"),
            "prompt-response": response("prompt-rag:{class}"),
            "document-embeddings-request": request("document-embeddings:{class}"),
            "document-embeddings-response": response("document-embeddings:{class}"),
        },
        "de-query:{class}": {
            request: request("document-embeddings:{class}"),
            response: response("document-embeddings:{class}"),
        },
        "prompt:{class}": {
            request: request("prompt:{class}"),
            response: response("prompt:{class}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
        },
        "prompt-rag:{class}": {
            request: request("prompt-rag:{class}"),
            response: response("prompt-rag:{class}"),
            "text-completion-request": request("text-completion-rag:{class}"),
            "text-completion-response": response("text-completion-rag:{class}"),
        },
        "mcp-tool:{class}": {
            request: request("mcp-tool:{class}"),
            response: response("mcp-tool:{class}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
        },
        "text-completion:{class}": {
            request: request("text-completion:{class}"),
            response: response("text-completion:{class}"),
        },
        "text-completion-rag:{class}": {
            request: request("text-completion-rag:{class}"),
            response: response("text-completion-rag:{class}"),
        },
        "metering:{class}": {
            input: response("text-completion:{class}"),
        },
        "metering-rag:{class}": {
            input: response("text-completion-rag:{class}"),
        },
    }
};

local agent_part = {
    "interfaces" +: {
        "agent": request_response("agent:{id}"),
    },
    "flow" +: {
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
        },
    },
    "class" +: {
    }
};

local load_part = {
    "interfaces" +: {
        "document-load": flow("document-load:{id}"),
        "text-load": flow("text-document-load:{id}"),
        "embeddings": request_response("embeddings:{class}"),
    },
    "flow" +: {
        "pdf-decoder:{id}": {
            input: flow("document-load:{id}"),
            output: flow("text-document-load:{id}"),
        },
        "chunker:{id}": {
            input: flow("text-document-load:{id}"),
            output: flow("chunk-load:{id}"),
        },
    },
    "class" +: {
        "embeddings:{class}": {
            request: request("embeddings:{class}"),
            response: response("embeddings:{class}"),
        },
    }
};

local kgcore_part = {
    "interfaces" +: {
    },
    "flow" +: {
        "kg-store:{id}": {
            "triples-input": flow("triples-store:{id}"),
            "graph-embeddings-input": flow("graph-embeddings-store:{id}"),
        },
    },
    "class" +: {
    }
};

{

    "document-rag+graph-rag": {
        description: "Supports GraphRAG and document RAG, no core creation",
        tags: ["document-rag", "graph-rag", "knowledge-extraction"],
    } +
      graphrag_part + documentrag_part + agent_part + load_part,

    "graph-rag": {
        description: "GraphRAG only",
        tags: ["graph-rag", "knowledge-extraction"],
    } +
      graphrag_part + agent_part + load_part,

    "document-rag": {
        description: "DocumentRAG only",
        tags: ["document-rag"],
    } +
      documentrag_part + load_part,

    "document-rag+graph-rag+kgcore": {
        description: "GraphRAG + DocumentRAG + knowledge core creation",
        tags: ["document-rag", "graph-rag", "knowledge-extraction"],
    } +
      graphrag_part + documentrag_part + agent_part + load_part +
      kgcore_part,
}

