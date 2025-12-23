local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";

{

    with:: function(key, value)
        self + {
            ["ceph-" + key]:: value,
        },

    "ceph-access-key":: "object-user",
    "ceph-secret-key":: "object-password",
    "ceph-cluster-id":: "ceph-cluster",

    ceph +: {

        create:: function(engine)

            // Volumes for persistent storage
            local vol_mon = engine.volume("ceph-mon").with_size("20G");
            local vol_mgr = engine.volume("ceph-mgr").with_size("20G");
            local vol_osd = engine.volume("ceph-osd").with_size("20G");
            local vol_rgw = engine.volume("ceph-rgw").with_size("20G");
            local vol_config = engine.volume("ceph-config").with_size("1G");

            // Common environment variables for all Ceph daemons
            local common_env = {
                CLUSTER: $["ceph-cluster-id"],
                CEPH_PUBLIC_NETWORK: "0.0.0.0/0",
                CEPH_DAEMON: "MON",  // This will be overridden per container
            };

            // MON (Monitor) container
            local mon_container =
                engine.container("ceph-mon")
                    .with_image(images.ceph)
                    .with_environment(common_env + {
                        CEPH_DAEMON: "MON",
                        MON_IP: "0.0.0.0",
                    })
                    .with_limits("1.0", "512M")
                    .with_reservations("0.5", "512M")
                    .with_port(6789, 6789, "mon")
                    .with_port(3300, 3300, "mon-msgr2")
                    .with_volume_mount(vol_mon, "/var/lib/ceph/mon")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // MGR (Manager) container
            local mgr_container =
                engine.container("ceph-mgr")
                    .with_image(images.ceph)
                    .with_environment(common_env + {
                        CEPH_DAEMON: "MGR",
                    })
                    .with_limits("1.0", "512M")
                    .with_reservations("0.5", "512M")
                    .with_port(7000, 7000, "mgr")
                    .with_port(8443, 8443, "dashboard")
                    .with_volume_mount(vol_mgr, "/var/lib/ceph/mgr")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // OSD (Object Storage Daemon) container
            local osd_container =
                engine.container("ceph-osd")
                    .with_image(images.ceph)
                    .with_environment(common_env + {
                        CEPH_DAEMON: "OSD",
                        OSD_TYPE: "directory",
                    })
                    .with_limits("1.0", "1024M")
                    .with_reservations("0.5", "1024M")
                    .with_port(6800, 6800, "osd")
                    .with_volume_mount(vol_osd, "/var/lib/ceph/osd")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // RGW (RADOS Gateway) container for S3 API
            local rgw_container =
                engine.container("ceph-rgw")
                    .with_image(images.ceph)
                    .with_environment(common_env + {
                        CEPH_DAEMON: "RGW",
                        RGW_NAME: "rgw0",
                        RGW_FRONTEND_PORT: "7480",
                        RGW_CIVETWEB_PORT: "7480",
                    })
                    .with_limits("1.0", "512M")
                    .with_reservations("0.5", "512M")
                    .with_port(7480, 7480, "s3")
                    .with_volume_mount(vol_rgw, "/var/lib/ceph/radosgw")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // Group all Ceph containers together
            local containerSet = engine.containers(
                "ceph", [
                    mon_container,
                    mgr_container,
                    osd_container,
                    rgw_container
                ]
            );

            // Service exposing all Ceph ports
            local service =
                engine.service(containerSet)
                .with_port(6789, 6789, "mon")
                .with_port(3300, 3300, "mon-msgr2")
                .with_port(7000, 7000, "mgr")
                .with_port(8443, 8443, "dashboard")
                .with_port(6800, 6800, "osd")
                .with_port(7480, 7480, "s3");

            engine.resources([
                vol_mon,
                vol_mgr,
                vol_osd,
                vol_rgw,
                vol_config,
                containerSet,
                service,
            ])

    },

}
