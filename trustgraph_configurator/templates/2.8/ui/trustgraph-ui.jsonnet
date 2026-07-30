local images = import "values/images.jsonnet";
local default_plugins = import "ui/plugins.json";

{

    "ui-plugins":: default_plugins,

    "ui-bundle":: {},

    "trustgraph-ui" +: {
    
        create:: function(engine)

            local cfgVol = engine.configVolume(
                "ui-plugin-cfg", "ui/config",
                {
                    "plugins.json": std.manifestJsonEx(
                        $["ui-plugins"], "  "
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

