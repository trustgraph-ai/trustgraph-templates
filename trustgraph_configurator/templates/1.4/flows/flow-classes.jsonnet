// Import all the modular flow components
local graphrag_part = import "graphrag.jsonnet";
local kg_base_part = import "kg-base.jsonnet";
local agent_extract_part = import "agent-extract.jsonnet";
local structured_part = import "structured.jsonnet";
local documentrag_part = import "documentrag.jsonnet";
local agent_part = import "agent.jsonnet";
local load_part = import "load.jsonnet";
local kgcore_part = import "kgcore.jsonnet";

{

    "everything": {
        description: "GraphRAG, DocumentRAG, structured data + knowledge cores",
        tags: [
            "document-rag", "graph-rag", "knowledge-extraction",
            "structured-data", "kgcore"
        ],
    } +
      graphrag_part + documentrag_part + agent_part + load_part +
      kg_base_part + structured_part,

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
      graphrag_part + agent_part + load_part + structured_part,

    "structured-data": {
        description: "Structured data only",
        tags: ["knowledge-extraction", "structured-data"],
    } +
      agent_part + load_part + structured_part,

}