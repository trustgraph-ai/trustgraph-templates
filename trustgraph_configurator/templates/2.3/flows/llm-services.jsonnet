// Shared LLM services module
// Provides text completion, prompt processing, and metering services
// Import this module in any flow that requires LLM functionality

local helpers = import "helpers.jsonnet";
local request = helpers.request;
local response = helpers.response;
local request_response_if = helpers.request_response_if;
local llm_parameters = import "llm-parameters.jsonnet";

{
    // Interfaces exposed by LLM services
    "interfaces" +: {
        "prompt": request_response_if("prompt:{id}"),
        "text-completion": request_response_if("text-completion:{id}"),
    },

    // LLM configuration parameters
    "parameters" +: llm_parameters,

    // Flow-level processors for LLM services
    "flow" +: {
        // Primary text completion service
        "text-completion:{id}": {
            topics: {
                request: request("text-completion:{id}"),
                response: response("text-completion:{id}"),
            },
            parameters: {
                model: "{llm-model}",
            },
        },

        // RAG-specific text completion (may use different model)
        "text-completion-rag:{id}": {
            topics: {
                request: request("text-completion-rag:{id}"),
                response: response("text-completion-rag:{id}"),
            },
            parameters: {
                model: "{llm-rag-model}",
            },
        },

        // Prompt processing service
        "prompt:{id}": {
            topics: {
                request: request("prompt:{id}"),
                response: response("prompt:{id}"),
                "text-completion-request": request("text-completion:{id}"),
                "text-completion-response": response("text-completion:{id}"),
            },
        },

        // RAG-specific prompt processing
        "prompt-rag:{id}": {
            topics: {
                request: request("prompt-rag:{id}"),
                response: response("prompt-rag:{id}"),
                "text-completion-request": request("text-completion-rag:{id}"),
                "text-completion-response": response("text-completion-rag:{id}"),
            },
        },

        // Usage metering for primary completion
        "metering:{id}": {
            topics: {
                input: response("text-completion:{id}"),
            },
        },

        // Usage metering for RAG completion
        "metering-rag:{id}": {
            topics: {
                input: response("text-completion-rag:{id}"),
            },
        },
    },

    "blueprint" +: {
    },
}
