// AWS Bedrock LLM Model Definitions
// Defines available models and their configurations for AWS Bedrock

{
    "type": "string",
    "description": "LLM model to use",
    "default": "anthropic.claude-3-5-sonnet-20241022-v2:0",
    "enum": [
        {
            id: "anthropic.claude-3-5-sonnet-20241022-v2:0",
            description: "Claude 3.5 Sonnet v2"
        },
        {
            id: "anthropic.claude-3-5-haiku-20241022-v1:0",
            description: "Claude 3.5 Haiku"
        },
        {
            id: "anthropic.claude-3-opus-20240229-v1:0",
            description: "Claude 3 Opus"
        },
        {
            id: "anthropic.claude-3-sonnet-20240229-v1:0",
            description: "Claude 3 Sonnet"
        },
        {
            id: "anthropic.claude-3-haiku-20240307-v1:0",
            description: "Claude 3 Haiku"
        },
        {
            id: "meta.llama3-1-405b-instruct-v1:0",
            description: "Llama 3.1 405B Instruct"
        },
        {
            id: "meta.llama3-1-70b-instruct-v1:0",
            description: "Llama 3.1 70B Instruct"
        },
        {
            id: "meta.llama3-1-8b-instruct-v1:0",
            description: "Llama 3.1 8B Instruct"
        },
        {
            id: "mistral.mistral-large-2407-v1:0",
            description: "Mistral Large"
        },
        {
            id: "mistral.mixtral-8x7b-instruct-v0:1",
            description: "Mixtral 8x7B Instruct"
        },
    ],
    "required": true
}
