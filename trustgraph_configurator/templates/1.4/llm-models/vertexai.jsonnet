// VertexAI LLM Model Definitions
// Defines available models and their configurations for Google's VertexAI platform

{
    "type": "string",
    "description": "LLM model to use",
    "default": "gemini-2.5-pro",
    "enum": [
        {
            id: "gemini-2.5-pro",
            description: "Gemini 2.5 Pro"
        },
        {
            id: "gemini-2.5-flash",
            description: "Gemini Flash"
        },
        {
            id: "gemini-2.5-flash-lite",
            description: "Gemini 2.5 Flash-Lite"
        },
    ],
    "required": true
}

