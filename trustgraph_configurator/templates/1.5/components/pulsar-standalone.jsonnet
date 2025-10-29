local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";

// This is a Pulsar configuration.  Standalone mode, only useful for dev.
//
// This also deploys the TrustGraph 'admin' container which initialises
// TrustGraph-specific namespaces etc.

{

    "pulsar" +: {

        create:: function(engine)

//            local confVolume = engine.volume("pulsar-conf").with_size("2G");
            local dataVolume = engine.volume("pulsar-data").with_size("20G");

            local container =
                engine.container("pulsar")
                    .with_image(images.pulsar)
                    .with_command(["bin/pulsar", "standalone"])
                    .with_environment({
                        "PULSAR_MEM": "-Xms600M -Xmx600M"
                    })
                    .with_limits("2.0", "1500M")
                    .with_reservations("1.0", "1500M")
//                    .with_volume_mount(confVolume, "/pulsar/conf")
                    .with_volume_mount(dataVolume, "/pulsar/data")
                    .with_port(6650, 6650, "bookie")
                    .with_port(8080, 8080, "http");

            local containerSet = engine.containers(
                "pulsar",
                [
                    container
                ]
            );

            local service =
                engine.service(containerSet)
                .with_port(6650, 6650, "bookie")
                .with_port(8080, 8080, "http");

            engine.resources([
//                confVolume,
                dataVolume,
                containerSet,
                service,
            ])

    }

}

