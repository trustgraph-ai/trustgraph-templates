local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";

{

    with:: function(key, value)
        self + {
            ["tgi-service-" + key]:: value,
        },

    "hf-token":: "NOT-SUPPLIED",

    // mistralai/Mistral-7B-Instruct-v0.3 is supported, this one isn't,
    // but this doesn't need an HF token to load
    "tgi-service-model":: "teknium/OpenHermes-2.5-Mistral-7B",

    "tgi-service-cpus":: "64.0",
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
                        "4096",
                        "--max-total-tokens",
                        "8192",
                        "--max-batch-size",
                        "4",
                        "--max-batch-prefill-tokens",
                        "16384",
                        "--max-waiting-tokens",
                        "7",
                        "--waiting-served-ratio",
                        "1.2",
                        "--max-concurrent-requests",
                        "64",
                        "--port",
                        "8899",
                    ])
                    .with_environment({
                        ENABLE_HPU_GRAPH: 'true',
                        FLASH_ATTENTION_RECOMPUTE: 'true',
                        HABANA_VISIBLE_DEVICES: "all",
                        LIMIT_HPU_GRAPH: 'true',
                        OMPI_MCA_btl_vader_single_copy_mechanism: "none",
                        PT_HPU_ENABLE_LAZY_COLLECTIVES: 'true',
                        USE_FLASH_ATTENTION: 'true',
                        PREFILL_BATCH_BUCKET_SIZE: "1",
                        BATCH_BUCKET_SIZE: "1",
//                        HF_TOKEN: $["hf-token"],
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

