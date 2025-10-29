local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";

{

    etcd +: {
    
        create:: function(engine)

            local vol = engine.volume("etcd").with_size("20G");

            local container =
                engine.container("etcd")
                    .with_image(images.etcd)
                    .with_command([
                        "etcd",
                        "-advertise-client-urls=http://127.0.0.1:2379",
                        "-listen-client-urls",
                        "http://0.0.0.0:2379",
                        "--data-dir",
                        "/etcd",
                    ])
                    .with_environment({
                        ETCD_AUTO_COMPACTION_MODE: "revision",
                        ETCD_AUTO_COMPACTION_RETENTION: "1000",
                        ETCD_QUOTA_BACKEND_BYTES: "4294967296",
                        ETCD_SNAPSHOT_COUNT: "50000"
                    })
                    .with_limits("1.0", "128M")
                    .with_reservations("0.25", "128M")
                    .with_port(2379, 2379, "api")
                    .with_volume_mount(vol, "/etcd");

            local containerSet = engine.containers(
                "etcd", [ container ]
            );

            local service =
                engine.service(containerSet)
                .with_port(2379, 2379, "api");

            engine.resources([
                vol,
                containerSet,
                service,
            ])

    },

}
