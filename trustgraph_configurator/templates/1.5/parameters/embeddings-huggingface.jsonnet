// Embeddings model definitions for fastembed
// Defines available models and their configurations for Fastembed

{
    "type": "string",
    "description": "Embeddings model to use",
    "default": "sentence-transformers/all-MiniLM-L6-v2",
    "enum": [
	{
	    "id": "all-MiniLM-L6-v2",
	    "description": "all-MiniLM-L6-v2: This model is known for its speed and efficiency, being significantly faster than similar models while still maintaining good quality.  It is a compact model that maps sentences and paragraphs to a 384-dimensional dense vector space, and is suitable for tasks like clustering, semantic search, information retrieval, and sentence similarity."
	},
	{
	    "id": "all-mpnet-base-v2",
	    "description": "all-mpnet-base-v2: This model is known for its high quality and is considered a leading pre-trained sentence transformer model.  It was trained using the microsoft/mpnet-base model and fine-tuned on a 1B sentence pairs dataset. It generates dense sentence embeddings, allowing similar sentences to be close together in the embedding space."
	},
	{
	    "id": "all-distilroberta-v1",
	    "description": "all-distilroberta-v1: A popular model, known for its performance and efficiency"
	},
	{
	    "id": "stsb-bert-large",
	    "description": "stsb-bert-large: A model that maps sentences and paragraphs to a 1024 dimensional dense vector space and can be used for tasks like clustering or semantic search."
	},
	{
	    "id": "sentence-camembert-large",
	    "description": "sentence-camembert-large: A model trained on French datasets, useful for French text embeddings"
	}
    ],
    "required": true
}
