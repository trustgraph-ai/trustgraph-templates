// Near AI LLM Model Definitions
// Defines available models and their configurations for Near AI's platform

{
    "type": "string",
    "description": "LLM model to use",
    "default": "anthropic/claude-sonnet-4-6",
    "enum": [
        {
            id: "anthropic/claude-opus-4-7",
            description: "Claude Opus 4.7 (Anthropic, maximum intelligence)"
        },
        {
            id: "anthropic/claude-sonnet-4-6",
            description: "Claude Sonnet 4.6 (Anthropic, fast + capable)"
        },
        {
            id: "anthropic/claude-haiku-4-5",
            description: "Claude Haiku 4.5 (Anthropic, ultra-fast)"
        },
        {
            id: "openai/gpt-5.4",
            description: "GPT-5.4 (OpenAI, flagship)"
        },
        {
            id: "openai/gpt-5.4-mini",
            description: "GPT-5.4 Mini (OpenAI, fast + affordable)"
        },
        {
            id: "openai/gpt-5.4-nano",
            description: "GPT-5.4 Nano (OpenAI, ultra-fast)"
        },
        {
            id: "google/gemini-3.5-flash",
            description: "Gemini 3.5 Flash (Google, fast)"
        },
        {
            id: "google/gemini-2.5-pro",
            description: "Gemini 2.5 Pro (Google, reasoning)"
        },
        {
            id: "google/gemini-2.5-flash",
            description: "Gemini 2.5 Flash (Google, balanced)"
        },
        {
            id: "deepseek/deepseek-v4.1-flash",
            description: "DeepSeek V4.1 Flash (fast reasoning)"
        },
        {
            id: "deepseek/deepseek-v3.2",
            description: "DeepSeek V3.2 (general-purpose)"
        },
        {
            id: "x-ai/grok-4.7",
            description: "Grok 4.7 (xAI, latest)"
        },
        {
            id: "x-ai/grok-4.6",
            description: "Grok 4.6 (xAI)"
        },
        {
            id: "qwen/qwen3.7-max",
            description: "Qwen 3.7 Max (Alibaba, large)"
        },
        {
            id: "moonshotai/kimi-k3",
            description: "Kimi K3 (Moonshot AI)"
        },
    ],
    "required": true
}
