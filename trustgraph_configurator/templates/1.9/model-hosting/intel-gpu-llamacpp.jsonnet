local images = import "values/images.jsonnet";

{

    with:: function(key, value)
        self + {
            ["llamacpp-service-" + key]:: value,
        },

    "llamacpp-service-model"::
        "bartowski/Mistral-Nemo-Instruct-2407-GGUF:Q8_0",

    "llamacpp-service-cpus":: "32.0",
    "llamacpp-service-memory":: "48G",
    "llamacpp-service-storage":: "48G",
    "llamacpp-service-hf-token":: null,

    "llamacpp-service" +: {
    
        create:: function(engine)

            local vol = engine.volume("llamacpp-storage")
                .with_size($["llamacpp-service-storage"]);

            local container =
                engine.container("llamacpp-service")
                    .with_image(images["llamacpp-service-intel"])
                    .with_entrypoint("")  // Clear default entrypoint
                    .with_command([
                      "--hf-repo",
                      $["llamacpp-service-model"],
                      "-ngl",
                      "99",
                      "--host",
                      "0.0.0.0",
                      "--port",
                      "7000"
                    ])
                    .with_environment({
                        HF_HOME: "/data",
                    } + (
                        if $["llamacpp-service-hf-token"] != null
                            then { HF_TOKEN: $["llamacpp-service-hf-token"] }
                            else {}
                    ))
                    .with_privileged(true)
                    .with_device("/dev/dri", "/dev/dri")
                    .with_ipc("host")
                    .with_capability("SYS_NICE")
                    .with_limits(
                        $["llamacpp-service-cpus"],
                        $["llamacpp-service-memory"]
                    )
                    .with_reservations(
                        $["llamacpp-service-cpus"],
                        $["llamacpp-service-memory"]
                    )
                    .with_port(7000, 7000, "llamacpp")
                    .with_bind_mount("/dev/dri/by-path", "/dev/dri/by-path")
                    .with_volume_mount(vol, "/data");

            local containerSet = engine.containers(
                "llamacpp-service", [ container ]
            );

            local service =
                engine.service(containerSet)
                .with_port(7000, 7000, "llamacpp");

            engine.resources([
                vol,
                containerSet,
                service,
            ])

    },

}
