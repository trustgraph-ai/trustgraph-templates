local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local minio = import "stores/minio.jsonnet";
local etcd = import "stores/etcd.jsonnet";

{

    milvus +: {
    
        create:: function(engine)

            local vol = engine.volume("milvus").with_size("20G");

            local container =
                engine.container("milvus")
                    .with_image(images.milvus)
                    .with_command([
                        "milvus", "run", "standalone"
                    ])
                    .with_environment({
                        ETCD_ENDPOINTS: "etcd:2379",
                        MINIO_ADDRESS: "minio:9000",
                    })
                    .with_limits("1.0", "256M")
                    .with_reservations("0.5", "256M")
                    .with_port(9091, 9091, "api")
                    .with_port(19530, 19530, "api2")
                    .with_volume_mount(vol, "/var/lib/milvus");

            local containerSet = engine.containers(
                "milvus", [ container ]
            );

            local service =
                engine.service(containerSet)
                .with_port(9091, 9091, "api")
                .with_port(19530, 19530, "api2");

            engine.resources([
                vol,
                containerSet,
                service,
            ])

    },

} + minio + etcd

