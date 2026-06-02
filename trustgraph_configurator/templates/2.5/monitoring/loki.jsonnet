local images = import "values/images.jsonnet";

{

    "loki" +: {
    
        create:: function(engine)

            local vol = engine.volume("loki-data").with_size("20G");

            local cfgVol = engine.configVolume(
                "loki-cfg", "loki",
		{
		    "local-config.yaml": importstr "loki/local-config.yaml",
		}
            );

            local container =
                engine.container("loki")
                    .with_image(images.loki)
                    .with_user(10001)
                    .with_group(10001)
                    .with_limits("1.0", "350M")
                    .with_reservations("0.5", "350M")
                    .with_port(3100, 3100, "http")
                    .with_volume_mount(cfgVol, "/etc/loki/")
                    .with_volume_mount(vol, "/loki");

            local containerSet = engine.containers(
                "loki", [ container ]
            );

            local service =
                engine.internalService("loki", containerSet)
                .with_port(3100, 3100, "http");

            engine.resources([
                cfgVol,
                vol,
                containerSet,
                service,
            ])

    },

}

