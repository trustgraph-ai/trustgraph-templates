local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";

{

    oxia +: {
    
        create:: function(engine)

            local vol = engine.volume("oxia").with_size("20G");

            local container =
                engine.container("oxia")
                    .with_image(images.oxia)
                    .with_command([
                        "oxia",
                        "standalone",
                    ])
                    .with_environment({
                    })
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M")
                    .with_port(6648, 6648, "api")
                    .with_volume_mount(vol, "/data");

            local containerSet = engine.containers(
                "oxia", [ container ]
            );

            local service =
                engine.service(containerSet)
                .with_port(6648, 6648, "api")
                .with_port(8080, 8080, "metrics");

            engine.resources([
                vol,
                containerSet,
                service,
            ])

    },

}
