// VertexAI LLM Model Definitions
// Defines available models and their configurations for Google's VertexAI platform

{
    "type": "string",
    "description": "LLM model to use",
    "default": "gemini-3.5-flash-lite",
    "enum": [
        // Gemini 3 models (preview)
        {
            id: "gemini-3.5-flash-lite",
            description: "Gemini 3.5 Flash Lite"
        },
        {
            id: "gemini-3.6-flash",
            description: "Gemini 3.6 Flash"
        },
        {
            id: "gemini-3.5-flash",
            description: "Gemini 3.5 Flash"
        },
        {
            id: "gemini-3.1-pro",
            description: "Gemini 3.1 Pro (preview)"
        },

        // Gemini 2.5 models
        {
            id: "gemini-2.5-pro",
            description: "Gemini 2.5 Pro"
        },
        {
            id: "gemini-2.5-flash",
            description: "Gemini 2.5 Flash"
        },
        {
            id: "gemini-2.5-flash-lite",
            description: "Gemini 2.5 Flash Lite"
        },

        // Gemma models
        {
            id: "google/gemma-4-26b-a4b-it-maas",
            description: "Gemma 4 26B A4B"
        }
    ],
    "required": true
}

