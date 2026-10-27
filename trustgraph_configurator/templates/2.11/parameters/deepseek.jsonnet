// DeepSeek LLM Model Definitions
// Defines available models and their configurations for DeepSeek's platform

{
    "type": "string",
    "description": "LLM model to use",
    "default": "deepseek-chat",
    "enum": [
        {
            id: "deepseek-chat",
            description: "DeepSeek-V3 (general-purpose conversational)"
        },
        {
            id: "deepseek-reasoner",
            description: "DeepSeek-R1 (chain-of-thought reasoning)"
        },
    ],
    "required": true
}
