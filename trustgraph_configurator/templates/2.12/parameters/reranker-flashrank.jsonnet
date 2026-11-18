// Re-ranking model definitions for FlashRank
// Defines available models and their configurations for FlashRank

{
    "type": "string",
    "description": "Re-ranking model to use",
    "default": "ms-marco-MiniLM-L-12-v2",
    "enum": [
	{
	    "id": "ms-marco-MiniLM-L-12-v2",
	    "description": "ms-marco-MiniLM-L-12-v2 - good quality/speed balance"
	},
	{
	    "id": "ms-marco-TinyBERT-L-2-v2",
	    "description": "ms-marco-TinyBERT-L-2-v2 - small / fast"
	},
	{
	    "id": "ms-marco-MultiBERT-L-12",
	    "description": "ms-marco-MultiBERT-L-12 - multilingual"
	},
	{
	    "id": "ce-esci-MiniLM-L12-v2",
	    "description": "ce-esci-MiniLM-L12-v2 - e-commerce tuned"
	}
    ],
    "required": true
}
