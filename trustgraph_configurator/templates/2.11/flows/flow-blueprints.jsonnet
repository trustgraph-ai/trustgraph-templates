// TrustGraph Flow Blueprints Configuration
//
// We define building blocks and combine those to make the flow blueprints
// to save a lot of repetitive code

// Import all the modular flow components
local graph_store = import "graph-store.jsonnet";
local document_store = import "document-store.jsonnet";
local structured_store = import "structured-store.jsonnet";
local graphrag_extract = import "graphrag-extract.jsonnet";
local ontorag_extract = import "ontorag-extract.jsonnet";
local structured_extract = import "structured-extract.jsonnet";
local agent = import "agent.jsonnet";
local load = import "load.jsonnet";
local kgcore = import "kgcore.jsonnet";

{
    // This makes it easier to override in other templates by
    // modifying $["flow-blueprints"]["flow-blocks"]
    "flow-blocks":: {
        "graph-store": graph_store,
        "document-store": document_store,
        "structured-store": structured_store,
        "graphrag-extract": graphrag_extract,
        "ontorag-extract": ontorag_extract,
        "structured-extract": structured_extract,
        "agent": agent,
        "load": load,
        "kgcore": kgcore,
    },

    // Full system: Graph RAG + Document RAG + knowledge cores
    "everything": {
        description: "Graph RAG + Document RAG + knowledge cores",
        tags: ["document-rag", "graph-rag", "kgcore"],
    } +
      $["flow-blocks"]["graph-store"] +
      $["flow-blocks"]["document-store"] +
      $["flow-blocks"]["agent"] +
      $["flow-blocks"]["load"] +
      $["flow-blocks"]["graphrag-extract"] +
      $["flow-blocks"]["kgcore"] +
      $["flow-blocks"]["structured-store"],

    // Structured RAG only
    "structured": {
        description: "Structured data extraction and querying",
        tags: ["structured"],
    } +
      $["flow-blocks"]["structured-store"] +
      $["flow-blocks"]["structured-extract"] +
      $["flow-blocks"]["agent"] +
      $["flow-blocks"]["load"],

    // Ontology RAG + knowledge cores
    "ontology": {
        description: "Ontology RAG + knowledge cores",
        tags: ["onto-rag", "kgcore"],
    } +
      $["flow-blocks"]["graph-store"] +
      $["flow-blocks"]["ontorag-extract"] +
      $["flow-blocks"]["agent"] +
      $["flow-blocks"]["load"] +
      $["flow-blocks"]["kgcore"],

}
