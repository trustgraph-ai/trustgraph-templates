// DashScope (Alibaba Cloud) LLM Model Definitions
// Defines available Qwen models via the DashScope OpenAI-compatible API

{
    "type": "string",
    "description": "LLM model to use",
    "default": "qwen-plus",
    "enum": [
        {
            id: "qwen-max",
            description: "Qwen Max (most capable, complex reasoning)"
        },
        {
            id: "qwen-plus",
            description: "Qwen Plus (balanced performance and cost)"
        },
        {
            id: "qwen-turbo",
            description: "Qwen Turbo (fastest, high-throughput)"
        },
        {
            id: "qwen-long",
            description: "Qwen Long (extended context, up to 10M tokens)"
        },
        {
            id: "qwen-coder-plus",
            description: "Qwen Coder Plus (code-specialized, strong reasoning)"
        },
        {
            id: "qwen-coder-turbo",
            description: "Qwen Coder Turbo (fast code model)"
        },
        {
            id: "qwq-plus",
            description: "QwQ Plus (deep thinking, chain-of-thought reasoning)"
        },
    ],
    "required": true
}
