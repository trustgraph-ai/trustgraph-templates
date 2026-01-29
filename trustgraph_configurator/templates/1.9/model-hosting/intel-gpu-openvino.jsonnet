local images = import "values/images.jsonnet";

{

    with:: function(key, value)
        self + {
            ["openvino-service-" + key]:: value,
        },

    "openvino-service-model":: "llmware/mistral-nemo-instruct-2407-ov",
    "openvino-service-cpus":: "32.0",
    "openvino-service-memory":: "48G",
    "openvino-service-storage":: "48G",
    "openvino-service-cache-size":: 2,
    "openvino-service-hf-token":: null,

    "openvino-service" +: {

        create:: function(engine)

            local vol = engine.volume("openvino-storage")
                .with_size($["openvino-service-storage"]);

            local container =
                engine.container("openvino-service")
                    .with_image(images["openvino-service-gpu"])
                    .with_command([
                        "--source_model",
                        $["openvino-service-model"],
                        "--model_repository_path",
                        "/models",
                        "--task",
                        "text_generation",
                        "--rest_port",
                        "7000",
                        "--target_device",
                        "GPU",
                        "--cache_size",
                        std.toString($["openvino-service-cache-size"]),
                    ])
                    .with_environment({
                    } + (
                        if $["openvino-service-hf-token"] != null
                            then { HF_TOKEN: $["openvino-service-hf-token"] }
                            else {}
                    ))
                    .with_privileged(true)
                    .with_device("/dev/dri", "/dev/dri")
                    .with_ipc("host")
                    .with_capability("SYS_NICE")
                    .with_limits(
                        $["openvino-service-cpus"], $["openvino-service-memory"]
                    )
                    .with_reservations(
                        $["openvino-service-cpus"], $["openvino-service-memory"]
                    )
                    .with_port(7000, 7000, "openvino")
                    .with_bind_mount("/dev/dri/by-path", "/dev/dri/by-path")
                    .with_volume_mount(vol, "/models");

            local containerSet = engine.containers(
                "openvino-service", [ container ]
            );

            local service =
                engine.service(containerSet)
                .with_port(7000, 7000, "openvino");

            engine.resources([
                vol,
                containerSet,
                service,
            ])

    },

}
