// Claude LLM Model Definitions
// Defines available models and their configurations for Anthropic's Claude

{
    "type": "string",
    "description": "LLM model to use",
    "default": "claude-sonnet-4-6",
    "enum": [
        {
            id: "claude-opus-5-5",
            description: "Claude Opus 5.5"
        },
        {
            id: "claude-sonnet-5-5",
            description: "Claude Sonnet 5.5"
        },
        {
            id: "claude-haiku-5-5",
            description: "Claude Haiku 5.5"
        },
        {
            id: "claude-fable-5-1",
            description: "Claude Fable 5.1"
        },
        {
            id: "claude-opus-5",
            description: "Claude Opus 5"
        },
        {
            id: "claude-sonnet-5",
            description: "Claude Sonnet 5"
        },
        {
            id: "claude-fable-5",
            description: "Claude Fable 5"
        },
        {
            id: "claude-opus-4-8",
            description: "Claude Opus 4.8"
        },
        {
            id: "claude-opus-4-7",
            description: "Claude Opus 4.7"
        },
        {
            id: "claude-sonnet-4-6",
            description: "Claude Sonnet 4.6"
        },
        {
            id: "claude-opus-4-6",
            description: "Claude Opus 4.6"
        },
        {
            id: "claude-opus-4-5-20251101",
            description: "Claude Opus 4.5"
        },
        {
            id: "claude-haiku-4-5-20251001",
            description: "Claude Haiku 4.5"
        },
        {
            id: "claude-sonnet-4-5-20250929",
            description: "Claude Sonnet 4.5"
        },
    ],
    "required": true
}
