// TrustGraph Flow Blueprints Configuration
// Defines different flow combinations for various use cases
// Each flow blueprint combines multiple functional modules to create complete processing pipelines
//
// RAG Modes (4 types):
// - Document RAG: Uses document chunk embeddings (independent, can combine with others)
// - Graph RAG: Extracts definitions + relationships to graph (mutually exclusive with Ontology RAG)
// - Ontology RAG: Extracts using ontology definitions to graph (mutually exclusive with Graph RAG)
// - Structured RAG: Extracts objects to object store (independent, can combine with others)
//
// Module structure:
// - *-store: Storage and query infrastructure
// - *-extract: Extraction methods
//
// Available modules:
// - document-store + (no extraction needed - uses chunk embeddings directly)
// - graph-store + graphrag-extract OR ontorag-extract OR agent-extract
// - structured-store + structured-extract
// - agent: AI agent orchestration
// - load: Document loading and preprocessing
// - kgcore: Knowledge graph core storage

// Import all the modular flow components
local graph_store = import "graph-store.jsonnet";
local document_store = import "document-store.jsonnet";
local structured_store = import "structured-store.jsonnet";
local graphrag_extract = import "graphrag-extract.jsonnet";
local ontorag_extract = import "ontorag-extract.jsonnet";
local structured_extract = import "structured-extract.jsonnet";
local agent_extract = import "agent-extract.jsonnet";
local agent = import "agent.jsonnet";
local load = import "load.jsonnet";
local kgcore = import "kgcore.jsonnet";

{

    // Complete TrustGraph system with all capabilities
    // Includes GraphRAG, DocumentRAG, structured data processing, and knowledge cores
    "everything": {
        description: "GraphRAG, DocumentRAG, structured data + knowledge cores",
        tags: [
            "document-rag", "graph-rag", "knowledge-extraction",
            "structured-data", "kgcore"
        ],
    } +
      graph_store + document_store + structured_store + agent + load +
      graphrag_extract + structured_extract,

    // Dual RAG system without knowledge core creation
    // Combines both document and graph-based retrieval
    "document-rag+graph-rag": {
        description: "Supports GraphRAG and document RAG, no core creation",
        tags: ["document-rag", "graph-rag", "knowledge-extraction"],
    } +
      graph_store + document_store + agent + load + graphrag_extract,

    // Graph-based RAG only
    // Uses knowledge graphs for context-aware question answering
    "graph-rag": {
        description: "GraphRAG only",
        tags: ["graph-rag", "knowledge-extraction"],
    } +
      graph_store + agent + load + graphrag_extract,

    // Ontology-based RAG only
    // Uses ontology definitions for knowledge extraction
    "onto-rag": {
        description: "Ontology RAG only",
        tags: ["onto-rag", "knowledge-extraction"],
    } +
      graph_store + agent + load + ontorag_extract,

    // Document-based RAG only
    // Uses document embeddings for semantic search and answers
    "document-rag": {
        description: "DocumentRAG only",
        tags: ["document-rag"],
    } +
      document_store + load,

    // Full RAG system with knowledge core creation
    // Includes both RAG types plus persistent knowledge storage
    "document-rag+graph-rag+kgcore": {
        description: "GraphRAG + DocumentRAG + knowledge core creation",
        tags: ["document-rag", "graph-rag", "knowledge-extraction"],
    } +
      graph_store + document_store + agent + load +
      kgcore + graphrag_extract,

    // GraphRAG with advanced agent-based extraction
    // Uses AI agents for sophisticated knowledge extraction
    "graph-rag+agent-extract": {
        description: "GraphRAG + agent extract",
        tags: ["graph-rag", "knowledge-extraction", "agent-extract"],
    } +
      graph_store + agent + load + agent_extract,

    // GraphRAG with structured data processing
    // Combines knowledge graphs with structured data queries
    "graph-rag+structured-data": {
        description: "GraphRAG + structured data",
        tags: ["graph-rag", "knowledge-extraction", "structured-data"],
    } +
      graph_store + structured_store + agent + load +
      graphrag_extract + structured_extract,

    // Structured data processing only
    // Handles structured data extraction and NLP queries
    "structured-data": {
        description: "Structured data only",
        tags: ["knowledge-extraction", "structured-data"],
    } +
      structured_store + agent + load + structured_extract,

}
