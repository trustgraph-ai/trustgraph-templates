{

   // Essentials
   "trustgraph-base": import "components/trustgraph.jsonnet",
   "rev-gateway": import "components/rev-gateway.jsonnet",
   "pulsar": import "components/pulsar.jsonnet",

   // LLMs
   "azure": import "components/azure.jsonnet",
   "azure-openai": import "components/azure-openai.jsonnet",
   "bedrock": import "components/bedrock.jsonnet",
   "claude": import "components/claude.jsonnet",
   "cohere": import "components/cohere.jsonnet",
   "googleaistudio": import "components/googleaistudio.jsonnet",
   "llamafile": import "components/llamafile.jsonnet",
   "lmstudio": import "components/lmstudio.jsonnet",
   "mistral": import "components/mistral.jsonnet",
   "ollama": import "components/ollama.jsonnet",
   "openai": import "components/openai.jsonnet",
   "vertexai": import "components/vertexai.jsonnet",
   "tgi": import "components/tgi.jsonnet",
   "vllm": import "components/vllm.jsonnet",

   // LLMs for RAG
   "azure-rag": import "components/azure-rag.jsonnet",
   "azure-openai-rag": import "components/azure-openai-rag.jsonnet",
   "bedrock-rag": import "components/bedrock-rag.jsonnet",
   "claude-rag": import "components/claude-rag.jsonnet",
   "cohere-rag": import "components/cohere-rag.jsonnet",
   "googleaistudio-rag": import "components/googleaistudio-rag.jsonnet",
   "llamafile-rag": import "components/llamafile-rag.jsonnet",
   "lmstudio-rag": import "components/lmstudio-rag.jsonnet",
   "mistral-rag": import "components/mistral-rag.jsonnet",
   "ollama-rag": import "components/ollama-rag.jsonnet",
   "openai-rag": import "components/openai-rag.jsonnet",
   "vertexai-rag": import "components/vertexai-rag.jsonnet",
   "tgi-rag": import "components/tgi-rag.jsonnet",
   "vllm-rag": import "components/vllm-rag.jsonnet",

   "tgi-service-cpu": import "components/tgi-service-cpu.jsonnet",
   "tgi-service-intel-gpu": import "components/tgi-service-intel-gpu.jsonnet",
   "tgi-service-gaudi": import "components/tgi-service-gaudi.jsonnet",

   "vllm-service-intel-gpu": import "components/vllm-service-intel-gpu.jsonnet",
   "vllm-service-gaudi": import "components/vllm-service-gaudi.jsonnet",
   "vllm-service-nvidia": import "components/vllm-service-nvidia.jsonnet",

   // Embeddings
   "embeddings-ollama": import "components/embeddings-ollama.jsonnet",
   "embeddings-hf": import "components/embeddings-hf.jsonnet",
   "embeddings-fastembed": import "components/embeddings-fastembed.jsonnet",

   // OCR options
   "ocr": import "components/ocr.jsonnet",
   "mistral-ocr": import "components/mistral-ocr.jsonnet",

   // Vector stores
   "vector-store-milvus": import "components/milvus.jsonnet",
   "vector-store-qdrant": import "components/qdrant.jsonnet",
   "vector-store-pinecone": import "components/pinecone.jsonnet",

   // Triples stores
   "triple-store-cassandra": import "components/cassandra.jsonnet",
   "triple-store-neo4j": import "components/neo4j.jsonnet",
   "triple-store-falkordb": import "components/falkordb.jsonnet",
   "triple-store-memgraph": import "components/memgraph.jsonnet",

   // Observability support
   "grafana": import "components/grafana.jsonnet",

   // Pulsar manager is a UI for Pulsar.  Uses a LOT of memory
   "pulsar-manager": import "components/pulsar-manager.jsonnet",

   "override-recursive-chunker": import "components/chunker-recursive.jsonnet",

   // The prompt manager
   "prompt-overrides": import "components/prompt-overrides.jsonnet",

   // Archaic - part of core system, just making sure these don't
   // cause a failure
   "workbench-ui": {},
   "prompt-template": {},
   "agent-manager-react": {},
   "graph-rag": {},
   "document-rag": {},
   "librarian": {},

   // Does nothing.  But, can be a hack to overwrite parameters
   "null": {},

}
