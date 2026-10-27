// GLM (Zhipu AI / BigModel) LLM Model Definitions
// Defines available models via the Zhipu AI OpenAI-compatible API

{
    "type": "string",
    "description": "LLM model to use",
    "default": "glm-4-plus",
    "enum": [
        {
            id: "glm-4-plus",
            description: "GLM-4 Plus (flagship, high capability)"
        },
        {
            id: "glm-4",
            description: "GLM-4 (standard)"
        },
        {
            id: "glm-4-air",
            description: "GLM-4 Air (faster, cheaper)"
        },
        {
            id: "glm-4-airx",
            description: "GLM-4 AirX (fastest inference)"
        },
        {
            id: "glm-4-long",
            description: "GLM-4 Long (extended context, up to 1M tokens)"
        },
        {
            id: "glm-4-flash",
            description: "GLM-4 Flash (lightest, cheapest)"
        },
        {
            id: "glm-4-flashx",
            description: "GLM-4 FlashX (optimized flash)"
        },
    ],
    "required": true
}
