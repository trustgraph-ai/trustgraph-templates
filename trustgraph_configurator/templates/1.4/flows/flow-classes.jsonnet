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
        "text-completion": request_response("text-completion:{class}"),
    },
    "parameters" +: {
        "model": "llm-model",
    },
    "flow" +: {
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
        "text-completion:{class}": {
            request: request("text-completion:{class}"),
            response: response("text-completion:{class}"),
            model: "{model}",
        },
        "text-completion-rag:{class}": {
            request: request("text-completion-rag:{class}"),
            response: response("text-completion-rag:{class}"),
            model: "{model}",
        },
        "metering:{class}": {
            input: response("text-completion:{class}"),
        },
        "metering-rag:{class}": {
            input: response("text-completion-rag:{class}"),
        },
    }
};

local kg_base_part = {
    "interfaces" +: {
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
    },
    "class" +: {
    }
};

local agent_extract_part = {
    "interfaces" +: {
    },
    "flow" +: {
        "kg-extract-agent:{id}": {
            input: flow("chunk-load:{id}"),
            triples: flow("triples-store:{id}"),
            "entity-contexts": flow("entity-contexts-load:{id}"),
            "agent-request": request("agent:{id}"),
            "agent-response": response("agent:{id}"),
        },
    },
    "class" +: {
    }
};

local object_part = {
    "interfaces" +: {
        "embeddings": request_response("embeddings:{class}"),
        "prompt": request_response("prompt:{class}"),
        "text-completion": request_response("text-completion:{class}"),
        "objects-store": flow("objects-store:{id}"),
        "objects": request_response("objects:{class}"),
        "nlp-query": request_response("nlp-query:{class}"),
        "structured-query": request_response("structured-query:{class}"),
        "structured-diag": request_response("structured-diag:{class}"),
    },
    "parameters" +: {
        "model": "llm-model",
    },
    "flow" +: {
        "kg-extract-objects:{id}": {
            input: flow("chunk-load:{id}"),
            output: flow("objects-store:{id}"),
            "entity-contexts": flow("entity-contexts-load:{id}"),
            "prompt-request": request("prompt:{class}"),
            "prompt-response": response("prompt:{class}"),
        },
        "objects-write:{id}": {
            input: flow("objects-store:{id}"),
        },
    },
    "class" +: {
        "objects-query:{class}": {
            request: request("objects:{class}"),
            response: response("objects:{class}"),
        },
        "nlp-query:{class}": {
            request: request("nlp-query:{class}"),
            response: response("nlp-query:{class}"),
            "prompt-request": request("prompt-rag:{class}"),
            "prompt-response": response("prompt-rag:{class}"),
        },
        "structured-query:{class}": {
            request: request("structured-query:{class}"),
            response: response("structured-query:{class}"),
            "nlp-query-request": request("nlp-query:{class}"),
            "nlp-query-response": response("nlp-query:{class}"),
            "objects-query-request": request("objects:{class}"),
            "objects-query-response": response("objects:{class}"),
        },
        "structured-diag:{class}": {
            request: request("structured-diag:{class}"),
            response: response("structured-diag:{class}"),
            "prompt-request": request("prompt:{class}"),
            "prompt-response": response("prompt:{class}"),
        },
        "embeddings:{class}": {
            request: request("embeddings:{class}"),
            response: response("embeddings:{class}"),
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
        "text-completion:{class}": {
            request: request("text-completion:{class}"),
            response: response("text-completion:{class}"),
            model: "{model}",
        },
        "text-completion-rag:{class}": {
            request: request("text-completion-rag:{class}"),
            response: response("text-completion-rag:{class}"),
            model: "{model}",
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
    "parameters" +: {
        "model": "llm-model",
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
            model: "{model}",
        },
        "text-completion-rag:{class}": {
            request: request("text-completion-rag:{class}"),
            response: response("text-completion-rag:{class}"),
            model: "{model}",
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
        "mcp-tool": request_response("mcp-tool:{class}"),
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
            "structured-query-request": request("structured-query:{class}"),
            "structured-query-response": response("structured-query:{class}"),
        },
    },
    "class" +: {
        "mcp-tool:{class}": {
            request: request("mcp-tool:{class}"),
            response: response("mcp-tool:{class}"),
            "text-completion-request": request("text-completion:{class}"),
            "text-completion-response": response("text-completion:{class}"),
        },
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

    "everything": {
        description: "GraphRAG, DocumentRAG, structured data + knowledge cores",
        tags: [
            "document-rag", "graph-rag", "knowledge-extraction",
            "structured-data", "kgcore"
        ],
    } +
      graphrag_part + documentrag_part + agent_part + load_part +
      kg_base_part + object_part,

    "document-rag+graph-rag": {
        description: "Supports GraphRAG and document RAG, no core creation",
        tags: ["document-rag", "graph-rag", "knowledge-extraction"],
    } +
      graphrag_part + documentrag_part + agent_part + load_part + kg_base_part,

    "graph-rag": {
        description: "GraphRAG only",
        tags: ["graph-rag", "knowledge-extraction"],
    } +
      graphrag_part + agent_part + load_part + kg_base_part,

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
      kgcore_part + kg_base_part,

    "graph-rag+agent-extract": {
        description: "GraphRAG + agent extract",
        tags: ["graph-rag", "knowledge-extraction", "agent-extract"],
    } +
      graphrag_part + agent_part + load_part + agent_extract_part,

    "graph-rag+structured-data": {
        description: "GraphRAG + structured data",
        tags: ["graph-rag", "knowledge-extraction", "structured-data"],
    } +
      graphrag_part + agent_part + load_part + object_part,

    "structured-data": {
        description: "Structured data only",
        tags: ["knowledge-extraction", "structured-data"],
    } +
      agent_part + load_part + object_part,

}

