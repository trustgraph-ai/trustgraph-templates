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
            // Data volumes
            local vol_mon = engine.volume("ceph-mon").with_size("20G");
            local vol_mgr = engine.volume("ceph-mgr").with_size("20G");
            local vol_osd = engine.volume("ceph-osd").with_size("100G");
            local vol_rgw = engine.volume("ceph-rgw").with_size("20G");

            // Separate config volumes per daemon
            local vol_mon_config = engine.volume("ceph-mon-config").with_size("100M");
            local vol_mgr_config = engine.volume("ceph-mgr-config").with_size("100M");
            local vol_osd_config = engine.volume("ceph-osd-config").with_size("100M");
            local vol_rgw_config = engine.volume("ceph-rgw-config").with_size("100M");

            // Base environment for MON (bootstraps cluster)
            local mon_env = {
                CLUSTER: $["ceph-cluster-id"],
                FSID: $["ceph-fsid"],
                CEPH_PUBLIC_NETWORK: "0.0.0.0/0",
                CEPH_CLUSTER_NETWORK: "0.0.0.0/0",
                CEPH_CONF_OSD_POOL_DEFAULT_SIZE: "1",
                CEPH_CONF_OSD_POOL_DEFAULT_MIN_SIZE: "1",
                CEPH_CONF_OSD_CRUSH_CHOOSELEAF_TYPE: "0",
            };

            // Environment for non-MON daemons (fetch config from MON)
            local daemon_env = mon_env + {
                MON_HOST: "ceph-mon",
            };

            // MON (Monitor) container - bootstraps cluster on first run
            local mon_container =
                engine.container("ceph-mon")
                    .with_image(images.ceph)
                    .with_environment(mon_env + {
                        CEPH_DAEMON: "MON",
                        MON_IP: "auto",
                        MON_NAME: "mon0",
                    })
                    .with_limits("1.0", "1024M")
                    .with_reservations("0.5", "512M")
                    .with_port(6789, 6789, "mon")
                    .with_port(3300, 3300, "mon-msgr2")
                    .with_volume_mount(vol_mon, "/var/lib/ceph/mon")
                    .with_volume_mount(vol_mon_config, "/etc/ceph");

            // MGR (Manager) container
            local mgr_container =
                engine.container("ceph-mgr")
                    .with_image(images.ceph)
                    .with_environment(daemon_env + {
                        CEPH_DAEMON: "MGR",
                        MGR_NAME: "mgr0",
                    })
                    .with_limits("1.0", "1024M")
                    .with_reservations("0.5", "512M")
                    .with_port(7000, 7000, "mgr")
                    .with_port(8443, 8443, "dashboard")
                    .with_port(9283, 9283, "prometheus")
                    .with_volume_mount(vol_mgr, "/var/lib/ceph/mgr")
                    .with_volume_mount(vol_mgr_config, "/etc/ceph");

            // OSD (Object Storage Daemon) container
            local osd_container =
                engine.container("ceph-osd")
                    .with_image(images.ceph)
                    .with_environment(daemon_env + {
                        CEPH_DAEMON: "OSD_DIRECTORY",
                    })
                    .with_limits("2.0", "2048M")
                    .with_reservations("0.5", "1024M")
                    .with_port(6800, 6800, "osd")
                    .with_volume_mount(vol_osd, "/var/lib/ceph/osd")
                    .with_volume_mount(vol_osd_config, "/etc/ceph");

            // RGW (RADOS Gateway) container
            local rgw_container =
                engine.container("ceph-rgw")
                    .with_image(images.ceph)
                    .with_environment(daemon_env + {
                        CEPH_DAEMON: "RGW",
                        RGW_NAME: "rgw0",
                        RGW_CIVETWEB_PORT: "7480",
                    })
                    .with_limits("1.0", "1024M")
                    .with_reservations("0.5", "512M")
                    .with_port(7480, 7480, "s3")
                    .with_volume_mount(vol_rgw, "/var/lib/ceph/radosgw")
                    .with_volume_mount(vol_rgw_config, "/etc/ceph");

            // Init container - creates S3 user, retries until success
            local vol_init_config = engine.volume("ceph-init-config").with_size("100M");
            local init_container =
                engine.container("ceph-init")
                    .with_image(images.ceph)
                    .with_environment(daemon_env + {
                        RGW_ACCESS_KEY: $["ceph-access-key"],
                        RGW_SECRET_KEY: $["ceph-secret-key"],
                    })
                    .with_limits("0.5", "256M")
                    .with_reservations("0.1", "128M")
                    .with_volume_mount(vol_init_config, "/etc/ceph")
                    .with_command([
                        "bash", "-c", |||
                            set -e
                            echo "Waiting for Ceph cluster and RGW to be ready..."
                            until ceph health | grep -q "HEALTH_OK\|HEALTH_WARN"; do
                                echo "Cluster not ready, retrying in 5s..."
                                sleep 5
                            done
                            echo "Cluster is healthy."

                            until curl -sf http://ceph-rgw:7480 >/dev/null 2>&1; do
                                echo "RGW not ready, retrying in 5s..."
                                sleep 5
                            done
                            echo "RGW is ready."

                            echo "Creating S3 user..."
                            until radosgw-admin user create \
                                --uid="${RGW_ACCESS_KEY}" \
                                --display-name="Object Storage User" \
                                --access-key="${RGW_ACCESS_KEY}" \
                                --secret-key="${RGW_SECRET_KEY}" 2>/dev/null \
                            || radosgw-admin user info --uid="${RGW_ACCESS_KEY}" >/dev/null 2>&1; do
                                echo "User creation failed, retrying in 5s..."
                                sleep 5
                            done
                            echo "S3 user ready."

                            echo "Init complete. Sleeping forever..."
                            exec sleep infinity
                        |||,
                    ]);

            // Container sets
            local mon_containerSet = engine.containers("ceph-mon", [mon_container]);
            local mgr_containerSet = engine.containers("ceph-mgr", [mgr_container]);
            local osd_containerSet = engine.containers("ceph-osd", [osd_container]);
            local rgw_containerSet = engine.containers("ceph-rgw", [rgw_container]);
            local init_containerSet = engine.containers("ceph-init", [init_container]);

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
                vol_mon_config,
                vol_mgr_config,
                vol_osd_config,
                vol_rgw_config,
                vol_init_config,
                mon_containerSet,
                mgr_containerSet,
                osd_containerSet,
                rgw_containerSet,
                init_containerSet,
                mon_service,
                mgr_service,
                osd_service,
                rgw_service,
            ])
    },
}
