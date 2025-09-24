// TrustGraph Main Configuration
// Clean, modular composition of TrustGraph configuration
// Uses specialized modules for different aspects of config building

// Import dependencies
local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";
local default_prompts = import "prompts/default-prompts.jsonnet";
local token_costs = import "values/token-costs.jsonnet";
local flow_classes = import "flows/flow-classes.jsonnet";
local config_composer = import "config/config-composer.jsonnet";
local interface_descriptions = import "config/interface-descriptions.jsonnet";

// Main configuration object
local configuration = {

    // Prompt templates
    prompts:: default_prompts,

    // Tool definitions
    tools:: [
        {
            id: "knowledge-extraction",
            name: "Knowledge extraction",
            description: "Takes a chunk of text and extracts knowledge in definition and relationship formats. The input is a text chunk",
            type: "prompt",
            template: "agent-kg-extract",
            arguments: [
                {
                    "name": "text",
                    "type": "string",
                    "description": "The text chunk",
                }
            ],
        },
        {
            id: "knowledge-query",
            name: "Knowledge query",
            description: "This tool queries a knowledge base that holds information about domain-specific information.  The question should be a natural language question.",
            type: "knowledge-query",
            collection: "default",
            arguments: [
                {
                    name: "question",
                    type: "string",
                    description: "A simple natural language question.",
                }
            ]
        },
        {
            id: "llm-completion",
            name: "LLM text completion",
            type: "text-completion",
            description: "This tool queries an LLM for non-domain-specific information.  The question should be a natural language question.",
            arguments: [
                {
                    name: "question",
                    type: "string",
                    description: "The question which should be asked of the LLM.",
                }
            ]
        }
    ],

    // MCP configuration
    mcp:: {},

    // Flow classes reference
    "flow-classes":: flow_classes,

    // Default model and flow parameters
    default_llm_model:: "gemma2:9b",
    flow_init_parameters:: {
        "model": $["default_llm_model"],
    },

    // Interface descriptions for external endpoints
    "interface-descriptions":: interface_descriptions,

    // Parameter type definitions
    "parameter-types":: {
        "llm-model": {
            "type": "string",
            "description": "LLM model to use",
            "default": "gpt-4",
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
            "required": false
        },
    },

    // Token costs
    "token-costs":: token_costs,

    // Build the complete configuration using the composer
    configuration:: config_composer.build({
        flow_classes: $["flow-classes"],
        default_flow_class: "everything",
        default_flow_id: "default",
        flow_init_parameters: $["flow_init_parameters"],
        prompts: $["prompts"],
        tools: $["tools"],
        mcp: $["mcp"],
        interface_descriptions: $["interface-descriptions"],
        parameter_types: $["parameter-types"],
        token_costs: $["token-costs"],
    }),

} + default_prompts;

// Export the final configuration
configuration