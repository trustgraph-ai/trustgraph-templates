// Claude LLM Model Definitions
// Defines available models and their configurations for Anthropic's Claude

{
    "type": "string",
    "description": "LLM model to use",
    "default": "claude-3-5-sonnet-20241022",
    "enum": [
        {
            id: "claude-3-5-sonnet-20241022",
            description: "Claude 3.5 Sonnet (latest)"
        },
        {
            id: "claude-3-5-haiku-20241022",
            description: "Claude 3.5 Haiku"
        },
        {
            id: "claude-3-opus-20240229",
            description: "Claude 3 Opus"
        },
        {
            id: "claude-3-sonnet-20240229",
            description: "Claude 3 Sonnet"
        },
        {
            id: "claude-3-haiku-20240307",
            description: "Claude 3 Haiku"
        },
    ],
    "required": true
}