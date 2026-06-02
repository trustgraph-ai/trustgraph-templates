local images = import "values/images.jsonnet";

{

    "trustgraph-ui" +: {
    
        create:: function(engine)

            local container =
                engine.container("trustgraph-ui")
                    .with_image(images["ui"])
                    .with_limits("0.1", "256M")
                    .with_reservations("0.1", "256M")
                    .with_port(8888, 8888, "ui");

            local containerSet = engine.containers(
                "trustgraph-ui", [ container ]
            );

            local service =
                engine.service("trustgraph-ui", containerSet)
                .with_port(8888, 8888, "ui")
                ;

            engine.resources([
                containerSet,
                service,
            ])

    },

}

