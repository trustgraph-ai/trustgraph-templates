local images = import "values/images.jsonnet";
local default_components = import "ui/components.json";
local default_action_buttons = import "ui/action-buttons.json";
local default_guidance = import "ui/guidance.json";

{

    "ui-components":: default_components,

    "ui-action-buttons":: default_action_buttons,

    "ui-guidance":: default_guidance,

    "ui-bundle":: {},

    "ui-proxies":: [
        {
            path: "/demo-data",
            url: "https://github.com/trustgraph-ai/demo-standard/raw/refs/heads/master/datasets",
        },
    ],

    "trustgraph-ui" +: {

        create:: function(engine)

            local proxyArgs = std.flatMap(
                function(p) ["--proxy", p.path + "=" + p.url],
                $["ui-proxies"]
            );

            local cfgVol = engine.configVolume(
                "ui-plugin-cfg", "ui/config",
                {
                    "components.json": std.manifestJsonEx(
                        $["ui-components"], "  "
                    ),
                    "action-buttons.json": std.manifestJsonEx(
                        $["ui-action-buttons"], "  "
                    ),
                    "guidance.json": std.manifestJsonEx(
                        $["ui-guidance"], "  "
                    ),
                }
            );

            local bundleVol = engine.configVolume(
                "ui-bundle-cfg", "ui/bundle",
                $["ui-bundle"]
            );

            local container =
                engine.container("trustgraph-ui")
                    .with_image(images["ui"])
                    .with_limits("0.1", "256M")
                    .with_reservations("0.1", "256M")
                    .with_port(8888, 8888, "ui")
                    .with_command(["service"] + proxyArgs)
                    .with_volume_mount(cfgVol, "/usr/lib/python3.12/site-packages/trustgraph_ui/ui/config/")
                    .with_volume_mount(bundleVol, "/usr/lib/python3.12/site-packages/trustgraph_ui/ui/bundle/");

            local containerSet = engine.containers(
                "trustgraph-ui", [ container ]
            );

            local service =
                engine.service("trustgraph-ui", containerSet)
                .with_port(8888, 8888, "ui")
                ;

            engine.resources([
                cfgVol,
                bundleVol,
                containerSet,
                service,
            ])

    },

}

