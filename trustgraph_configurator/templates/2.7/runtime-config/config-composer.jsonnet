// Configuration Composer Module
// Orchestrates the complete configuration building process
// Combines all components into the final TrustGraph configuration

{
    // Main function to build the complete configuration
    build: function(config_spec)

        // Extract configuration parameters
        local flow_blueprints = config_spec.flow_blueprints;

        // Return object with nested configuration (for backwards
        // compatibility)
        {

            // Create function (for backwards compatibility)
            create: function(engine) {},

            // The actual configuration object
            configuration: {

                // Prompts configuration
                prompt: {
                    "system": config_spec.prompts["system-template"],
                    "template-index": std.objectFieldsAll(
                        config_spec.prompts.templates
                    ),
                } + {
                    ["template." + template.key]: template.value
                    for template in std.objectKeysValuesAll(
                        config_spec.prompts.templates
                    )
                },

                // Tools configuration
                tool: {
                    [tool.id]: tool
                    for tool in config_spec.tools
                },

                // MCP configuration
                mcp: config_spec.mcp,

                // Agent orchestrator
                "agent-pattern": config_spec.agent_patterns,
                "agent-task-type": config_spec.agent_task_types,

                // Flow blueprints reference
                "flow-blueprint": flow_blueprints,

                // Interface descriptions
                "interface-description": config_spec.interface_descriptions,

                // Active flow processors — each processor is its own
                // config type keyed as "processor:<name>", with flow
                // variants (e.g. "default", "flow2") as sub-keys.
 
                // Token costs and parameter types
                "token-cost": config_spec.token_costs,
                "parameter-type": config_spec.parameter_types,

                // Collections configuration
                "collection": config_spec.collection,

            },
        },
}
