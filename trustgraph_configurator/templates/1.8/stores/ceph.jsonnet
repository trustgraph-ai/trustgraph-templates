local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";

{
    with:: function(key, value)
        self + {
            ["ceph-" + key]:: value,
        },

    // Ceph credentials and cluster settings
    "ceph-access-key":: "object-user",
    "ceph-secret-key":: "object-password",
    "ceph-cluster-id":: "ceph",
    "ceph-fsid":: "a7f64266-0894-4f1e-a635-d0aeaca0e993",

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
                FSID: $["ceph-fsid"],
                CEPH_PUBLIC_NETWORK: "0.0.0.0/0",
                CEPH_CLUSTER_NETWORK: "0.0.0.0/0",
                // Single node / dev settings
                CEPH_CONF_OSD_POOL_DEFAULT_SIZE: "1",
                CEPH_CONF_OSD_POOL_DEFAULT_MIN_SIZE: "1",
                CEPH_CONF_OSD_CRUSH_CHOOSELEAF_TYPE: "0",
            };

            // MON (Monitor) container - bootstraps cluster on first run
            local mon_container =
                engine.container("ceph-mon")
                    .with_image(images.ceph)
                    .with_environment(common_env + {
                        CEPH_DAEMON: "MON",
                        MON_IP: "auto",
                        MON_NAME: "mon0",
                    })
                    .with_limits("1.0", "1024M")
                    .with_reservations("0.5", "512M")
                    .with_port(6789, 6789, "mon")
                    .with_port(3300, 3300, "mon-msgr2")
                    .with_volume_mount(vol_mon, "/var/lib/ceph/mon")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // MGR (Manager) container - retries until MON available
            local mgr_container =
                engine.container("ceph-mgr")
                    .with_image(images.ceph)
                    .with_environment(common_env + {
                        CEPH_DAEMON: "MGR",
                        MGR_NAME: "mgr0",
                    })
                    .with_limits("1.0", "1024M")
                    .with_reservations("0.5", "512M")
                    .with_port(7000, 7000, "mgr")
                    .with_port(8443, 8443, "dashboard")
                    .with_port(9283, 9283, "prometheus")
                    .with_volume_mount(vol_mgr, "/var/lib/ceph/mgr")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // OSD (Object Storage Daemon) container - retries until MON available
            local osd_container =
                engine.container("ceph-osd")
                    .with_image(images.ceph)
                    .with_environment(common_env + {
                        CEPH_DAEMON: "OSD_DIRECTORY",
                    })
                    .with_limits("2.0", "2048M")
                    .with_reservations("0.5", "1024M")
                    .with_port(6800, 6800, "osd")
                    .with_volume_mount(vol_osd, "/var/lib/ceph/osd")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // RGW (RADOS Gateway) container - retries until cluster ready
            local rgw_container =
                engine.container("ceph-rgw")
                    .with_image(images.ceph)
                    .with_environment(common_env + {
                        CEPH_DAEMON: "RGW",
                        RGW_NAME: "rgw0",
                        RGW_CIVETWEB_PORT: "7480",
                    })
                    .with_limits("1.0", "1024M")
                    .with_reservations("0.5", "512M")
                    .with_port(7480, 7480, "s3")
                    .with_volume_mount(vol_rgw, "/var/lib/ceph/radosgw")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // Container sets
            local mon_containerSet = engine.containers("ceph-mon", [mon_container]);
            local mgr_containerSet = engine.containers("ceph-mgr", [mgr_container]);
            local osd_containerSet = engine.containers("ceph-osd", [osd_container]);
            local rgw_containerSet = engine.containers("ceph-rgw", [rgw_container]);

            // Services
            local mon_service =
                engine.service(mon_containerSet)
                    .with_port(6789, 6789, "mon")
                    .with_port(3300, 3300, "mon-msgr2");

            local mgr_service =
                engine.service(mgr_containerSet)
                    .with_port(7000, 7000, "mgr")
                    .with_port(8443, 8443, "dashboard")
                    .with_port(9283, 9283, "prometheus");

            local osd_service =
                engine.service(osd_containerSet)
                    .with_port(6800, 6800, "osd");

            local rgw_service =
                engine.service(rgw_containerSet)
                    .with_port(7480, 7480, "s3");

            engine.resources([
                vol_mon,
                vol_mgr,
                vol_osd,
                vol_rgw,
                vol_config,
                mon_containerSet,
                mgr_containerSet,
                osd_containerSet,
                rgw_containerSet,
                mon_service,
                mgr_service,
                osd_service,
                rgw_service,
            ])
    },
}
