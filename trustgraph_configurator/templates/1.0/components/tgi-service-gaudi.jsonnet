local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";

{

    with:: function(key, value)
        self + {
            ["tgi-service-" + key]:: value,
        },

    "tgi-service-model":: "teknium/OpenHermes-2.5-Mistral-7B",
    "tgi-service-cpus":: "32.0",
    "tgi-service-memory":: "64G",

    "tgi-service" +: {
    
        create:: function(engine)

            local vol = engine.volume("tgi-storage").with_size("20G");

            local container =
                engine.container("tgi-service")
                    .with_image(images["tgi-service-gaudi"])
                    .with_command([
                        "--model-id",
                        $["tgi-service-model"],
                        "--sharded",
                        "true",
                        "--num-shard",
                        "8",
                        "--max-input-tokens",
                        "2000",
                        "--max-total-tokens",
                        "4000",
                        "--max-batch-size",
                        "32",
                        "--max-batch-prefill-tokens",
                        "2048",
                        "--max-waiting-tokens",
                        "7",
                        "--waiting-served-ratio",
                        "1.2",
                        "--max-concurrent-requests",
                        "64",
                        "--port",
                        "8899"
                    ])
                    .with_environment({
                        PT_HPU_ENABLE_LAZY_COLLECTIVES: "true",
                        HABANA_VISIBLE_DEVICES: "all",
                        OMPI_MCA_btl_vader_single_copy_mechanism: "none",
//                        HF_TOKEN=$hf_token,
                        ENABLE_HPU_GRAPH: "true",
                        LIMIT_HPU_GRAPH: "true",
                        USE_FLASH_ATTENTION: "true",
                        FLASH_ATTENTION_RECOMPUTE: "true",
                    })
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

