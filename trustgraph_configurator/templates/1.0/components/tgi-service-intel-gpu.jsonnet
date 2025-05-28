local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";

{

    with:: function(key, value)
        self + {
            ["tgi-service-" + key]:: value,
        },

    "tgi-service-model":: "teknium/OpenHermes-2.5-Mistral-7B",
    "tgi-service-cpus":: "8.0",
    "tgi-service-memory":: "16G",

    "tgi-service" +: {
    
        create:: function(engine)

            local vol = engine.volume("tgi-storage").with_size("20G");

            local container =
                engine.container("tgi-service")
                    .with_image(images["tgi-service-intel-xpu"])
                    .with_command([
                        "--model-id",
                        $["tgi-service-model"],
                        "--cuda-graphs",
                        "0",
                        "--port",
                        "8899"
                    ])
                    .with_privileged(true)
                    .with_device("/dev/dri", "/dev/dri")
                    .with_ipc("host")
                    .with_capability("SYS_NICE")
                    .with_limits(
                        $["tgi-service-cpus"], $["tgi-service-memory"]
                    )
                    .with_reservations(
                        $["tgi-service-cpus"], $["tgi-service-memory"]
                    )
                    .with_port(8899, 8899, "tgi")
                    .with_volume_mount(vol, "/data");

            local containerSet = engine.containers(
                "tgi-service", [ container ]
            );

            local service =
                engine.service(containerSet)
                .with_port(8899, 8899, "tgi");

            engine.resources([
                vol,
                containerSet,
                service,
            ])

    },

}

/*

    volumes:
    - ./models:/data
    deploy:
      resources:
        limits:
          cpus: '8'
          memory: 16384M
        reservations:
          cpus: '8'
          memory: 16384M
    image: ghcr.io/huggingface/text-generation-inference:3.3.1-intel-xpu
    privileged: true
    cap_add:
    - SYS_NICE
    devices:
    - /dev/dri:/dev/dri
    ipc: host
    ports:
    - 8899:8899
    restart: on-failure:100

*/