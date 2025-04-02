local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

local prompts = import "prompts/mixtral.jsonnet";
local default_prompts = import "prompts/default-prompts.jsonnet";

{

    prompts:: default_prompts,
    tools:: [],

    local prompt_ix = std.manifestJsonMinified(
        std.objectFieldsAll($.prompts.templates)
    ),

    local prompt_settings = [
        "--set",
        "prompt.system=\"" + $["prompts"]["system-template"] + "\"",
    ] + std.flattenArrays([
        [
            "--set",
            "prompt.template." + p.key + "=" +
                std.manifestJsonMinified(p.value)
        ]
        for p in std.objectKeysValuesAll($.prompts.templates)
    ]) + [
        "--set",
        "prompt.template-index=" + prompt_ix,
    ],

    local tool_ix = std.manifestJsonMinified([t.id for t in $.tools]),

    local agent_settings = std.flattenArrays([
        [
            "--set",
            "agent.tool." + tool.id + "=" +
                std.manifestJsonMinified(tool)
        ]
        for tool in $.tools
    ]) + [
        "--set",
        "agent.tool-index=" + tool_ix,
    ],

    "init-trustgraph" +: {
    
        create:: function(engine)

            local container =
                engine.container("init-trustgraph")
                    .with_image(images.trustgraph_flow)
                    .with_command(
                        [
                            "tg-init-pulsar",
                            "-p",
                            url.pulsar_admin,
                        ] +
                        prompt_settings +
                        agent_settings
                    )
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "init-trustgraph", [ container ]
            );

            engine.resources([
                containerSet,
            ])

    },

} + default_prompts

/*
   "--tool-type",
                    ] + [
                        tool.id + "=" + tool.type
                        for tool in $.tools
                    ] + [
                        "--tool-description"
                    ] + [
                        tool.id + "=" + tool.description
                        for tool in $.tools
                    ] + [
                        "--tool-argument"
                    ] + [
                        "%s=%s:%s:%s" % [
                            tool.id, arg.name, arg.type, arg.description
                        ]
                        for tool in $.tools
                        for arg in tool.arguments
                    ]

*/