local images = import "values/images.jsonnet";
local default_navigation = import "ui/navigation.json";
local default_tabs = import "ui/tabs.json";
local default_components = import "ui/components.json";
local default_routes = import "ui/routes.json";
local default_action_buttons = import "ui/action-buttons.json";
local default_guidance = import "ui/guidance.json";
local default_tab_home = import "ui/tabs/home.json";
local default_tab_demos = import "ui/tabs/demos.json";
local default_tab_admin = import "ui/tabs/admin.json";

{

    "ui-navigation":: default_navigation,

    "ui-tabs":: default_tabs,

    "ui-components":: default_components,

    "ui-routes":: default_routes,

    "ui-action-buttons":: default_action_buttons,

    "ui-guidance":: default_guidance,

    "ui-tab-home":: default_tab_home,

    "ui-tab-demos":: default_tab_demos,

    "ui-tab-admin":: default_tab_admin,

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
                    "navigation.json": std.manifestJsonEx(
                        $["ui-navigation"], "  "
                    ),
                    "tabs.json": std.manifestJsonEx(
                        $["ui-tabs"], "  "
                    ),
                    "components.json": std.manifestJsonEx(
                        $["ui-components"], "  "
                    ),
                    "routes.json": std.manifestJsonEx(
                        $["ui-routes"], "  "
                    ),
                    "action-buttons.json": std.manifestJsonEx(
                        $["ui-action-buttons"], "  "
                    ),
                    "guidance.json": std.manifestJsonEx(
                        $["ui-guidance"], "  "
                    ),
                }
            );

            local tabsCfgVol = engine.configVolume(
                "ui-tabs-cfg", "ui/config/tabs",
                {
                    "home.json": std.manifestJsonEx(
                        $["ui-tab-home"], "  "
                    ),
                    "demos.json": std.manifestJsonEx(
                        $["ui-tab-demos"], "  "
                    ),
                    "admin.json": std.manifestJsonEx(
                        $["ui-tab-admin"], "  "
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
                    .with_volume_mount(tabsCfgVol, "/usr/lib/python3.12/site-packages/trustgraph_ui/ui/config/tabs/")
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
                tabsCfgVol,
                bundleVol,
                containerSet,
                service,
            ])

    },

}

