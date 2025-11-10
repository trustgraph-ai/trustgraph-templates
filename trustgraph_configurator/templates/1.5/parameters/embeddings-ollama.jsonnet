// Embeddings model definitions for Ollama
// Defines available models and their configurations for Ollama

{
    "type": "string",
    "description": "Embeddings model to use",
    "default": "all-minilm:latest",
    "enum": [
	{
	    "id": "all-minilm:latest",
	    "description": "sentence-transformers/all-MiniLM-L6-v2: Text embeddings, Unimodal (text), English, 256 input tokens truncation, Prefixes for queries/documents: not necessary, 2021 year."
	},
	{
	    "id": "nomic-ai/nomic-embed-text-v1.5-Q",
	    "description": "nomic-ai/nomic-embed-text-v1.5-Q: Text embeddings, Multimodal (text, image), English, 8192 input tokens truncation, Prefixes for queries/documents: necessary, 2024 year."
	},
	{
	    "id": "mixedbread-ai/mxbai-embed-large-v1",
	    "description": "mixedbread-ai/mxbai-embed-large-v1: Text embeddings, Unimodal (text), English, 512 input tokens truncation, Prefixes for queries/documents: necessary, 2024 year."
	},
    ],
    "required": true
}
