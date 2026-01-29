local images = import "values/images.jsonnet";

{

    with:: function(key, value)
        self + {
            ["openvino-service-" + key]:: value,
        },

    "openvino-service-model":: "OpenVINO/Phi-3-mini-128k-instruct-int4-ov",
    "openvino-service-cpus":: "32.0",
    "openvino-service-memory":: "48G",
    "openvino-service-storage":: "48G",
    "openvino-service-hf-token":: null,

    "openvino-service" +: {

        create:: function(engine)

            local vol = engine.volume("openvino-storage")
                .with_size($["openvino-service-storage"]);

            local container =
                engine.container("openvino-service")
                    .with_image(images["openvino-service-gpu"])
                    .with_command([
                        "--model_name",
                        "model",
                        "--model_path",
                        $["openvino-service-model"],
                        "--port",
                        "7000",
                        "--target_device",
                        "GPU",
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
                    .with_group("video")
                    .with_group("render")
                    .with_capability("SYS_NICE")
                    .with_limits(
                        $["openvino-service-cpus"], $["openvino-service-memory"]
                    )
                    .with_reservations(
                        $["openvino-service-cpus"], $["openvino-service-memory"]
                    )
                    .with_port(7000, 7000, "openvino")
                    .with_bind_mount("/dev/dri/by-path", "/dev/dri/by-path")
                    .with_volume_mount(vol, "/root/.cache/huggingface");

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
