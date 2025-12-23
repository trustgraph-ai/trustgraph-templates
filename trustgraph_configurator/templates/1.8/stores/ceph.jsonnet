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

    // Pool redundancy settings - minimum 2 for fault tolerance
    "ceph-pool-size":: "2",
    "ceph-pool-min-size":: "2",

    ceph +: {
        create:: function(engine)
            // Data volumes - sized appropriately for production workloads
            local vol_mon = engine.volume("ceph-mon").with_size("20G");
            local vol_mgr = engine.volume("ceph-mgr").with_size("20G");
            local vol_osd = engine.volume("ceph-osd").with_size("100G");
            local vol_rgw = engine.volume("ceph-rgw").with_size("20G");

            // Shared config volume approach - ceph/daemon manages config sync
            // Each daemon mounts this but the daemon image handles coordination
            local vol_config = engine.volume("ceph-config").with_size("500M");

            // Base cluster environment - shared across all daemons
            local cluster_env = {
                CLUSTER: $["ceph-cluster-id"],
                FSID: $["ceph-fsid"],
                CEPH_PUBLIC_NETWORK: "0.0.0.0/0",
                CEPH_CLUSTER_NETWORK: "0.0.0.0/0",
                CEPH_CONF_OSD_POOL_DEFAULT_SIZE: $["ceph-pool-size"],
                CEPH_CONF_OSD_POOL_DEFAULT_MIN_SIZE: $["ceph-pool-min-size"],
                CEPH_CONF_OSD_CRUSH_CHOOSELEAF_TYPE: "0",
            };

            // MON-specific environment
            local mon_env = cluster_env + {
                CEPH_DAEMON: "MON",
                MON_NAME: "mon0",
                // Use service discovery - the service name resolves to the pod IP
                // The daemon image will bind to the resolved address
            };

            // Daemon environment for services that discover MON
            local daemon_env = cluster_env + {
                MON_HOST: "ceph-mon:6789",  // DNS-based service discovery
            };

            // MGR-specific environment
            local mgr_env = daemon_env + {
                CEPH_DAEMON: "MGR",
                MGR_NAME: "mgr0",
            };

            // OSD-specific environment
            local osd_env = daemon_env + {
                CEPH_DAEMON: "OSD",
                OSD_TYPE: "directory",
            };

            // RGW-specific environment
            local rgw_env = daemon_env + {
                CEPH_DAEMON: "RGW",
                RGW_NAME: "rgw0",
                RGW_FRONTEND_PORT: "7480",
            };

            // MON (Monitor) container - cluster state and quorum
            local mon_container =
                engine.container("ceph-mon")
                    .with_image(images.ceph)
                    .with_environment(mon_env)
                    .with_limits("1.0", "1536M")
                    .with_reservations("0.5", "1024M")
                    .with_port(6789, 6789, "mon")
                    .with_port(3300, 3300, "mon-msgr2")
                    .with_volume_mount(vol_mon, "/var/lib/ceph/mon")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // MGR (Manager) container - cluster management and dashboard
            local mgr_container =
                engine.container("ceph-mgr")
                    .with_image(images.ceph)
                    .with_environment(mgr_env)
                    .with_limits("1.0", "1536M")
                    .with_reservations("0.5", "1024M")
                    .with_port(7000, 7000, "mgr")
                    .with_port(8443, 8443, "dashboard")
                    .with_port(9283, 9283, "prometheus")
                    .with_volume_mount(vol_mgr, "/var/lib/ceph/mgr")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // OSD (Object Storage Daemon) - actual data storage
            // Increased resources to prevent OOM during recovery operations
            local osd_container =
                engine.container("ceph-osd")
                    .with_image(images.ceph)
                    .with_environment(osd_env)
                    .with_limits("2.0", "4096M")
                    .with_reservations("1.0", "2048M")
                    .with_port(6800, 6800, "osd")
                    .with_volume_mount(vol_osd, "/var/lib/ceph/osd")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // RGW (RADOS Gateway) - S3 API endpoint
            local rgw_container =
                engine.container("ceph-rgw")
                    .with_image(images.ceph)
                    .with_environment(rgw_env)
                    .with_limits("1.0", "1536M")
                    .with_reservations("0.5", "1024M")
                    .with_port(7480, 7480, "s3")
                    .with_volume_mount(vol_rgw, "/var/lib/ceph/radosgw")
                    .with_volume_mount(vol_config, "/etc/ceph");

            // Init container - one-time S3 user provisioning
            // Exits cleanly after completion instead of sleeping forever
            local init_container =
                engine.container("ceph-init")
                    .with_image(images.ceph)
                    .with_environment({
                        CLUSTER: $["ceph-cluster-id"],
                        MON_HOST: "ceph-mon:6789",
                        RGW_ACCESS_KEY: $["ceph-access-key"],
                        RGW_SECRET_KEY: $["ceph-secret-key"],
                    })
                    .with_limits("0.5", "512M")
                    .with_reservations("0.25", "256M")
                    .with_volume_mount(vol_config, "/etc/ceph")
                    .with_command([
                        "bash", "-c", |||
                            set -e

                            # Wait for cluster health
                            echo "Waiting for Ceph cluster to be healthy..."
                            MAX_ATTEMPTS=60
                            ATTEMPT=0
                            until ceph --cluster ${CLUSTER} health 2>/dev/null | grep -q "HEALTH_OK\|HEALTH_WARN"; do
                                ATTEMPT=$((ATTEMPT+1))
                                if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
                                    echo "ERROR: Cluster failed to become healthy after ${MAX_ATTEMPTS} attempts"
                                    exit 1
                                fi
                                echo "Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: Cluster not ready, retrying in 5s..."
                                sleep 5
                            done
                            echo "Cluster is healthy."

                            # Wait for RGW availability
                            echo "Waiting for RGW to be ready..."
                            ATTEMPT=0
                            until curl -sf http://ceph-rgw:7480 >/dev/null 2>&1; do
                                ATTEMPT=$((ATTEMPT+1))
                                if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
                                    echo "ERROR: RGW failed to become ready after ${MAX_ATTEMPTS} attempts"
                                    exit 1
                                fi
                                echo "Attempt ${ATTEMPT}/${MAX_ATTEMPTS}: RGW not ready, retrying in 5s..."
                                sleep 5
                            done
                            echo "RGW is ready."

                            # Idempotent S3 user creation
                            echo "Provisioning S3 user: ${RGW_ACCESS_KEY}"
                            if radosgw-admin --cluster ${CLUSTER} user info --uid="${RGW_ACCESS_KEY}" >/dev/null 2>&1; then
                                echo "User ${RGW_ACCESS_KEY} already exists, skipping creation."
                            else
                                echo "Creating new S3 user: ${RGW_ACCESS_KEY}"
                                radosgw-admin --cluster ${CLUSTER} user create \
                                    --uid="${RGW_ACCESS_KEY}" \
                                    --display-name="Object Storage User" \
                                    --access-key="${RGW_ACCESS_KEY}" \
                                    --secret-key="${RGW_SECRET_KEY}"
                                echo "S3 user created successfully."
                            fi

                            echo "Initialization complete. Exiting."
                            exit 0
                        |||,
                    ]);

            // Container sets - each daemon gets its own for K8s node distribution
            local mon_containerSet = engine.containers("ceph-mon", [mon_container]);
            local mgr_containerSet = engine.containers("ceph-mgr", [mgr_container]);
            local osd_containerSet = engine.containers("ceph-osd", [osd_container]);
            local rgw_containerSet = engine.containers("ceph-rgw", [rgw_container]);
            local init_containerSet = engine.containers("ceph-init", [init_container]);

            // Services - expose daemon ports for inter-daemon communication
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
                // Volumes
                vol_mon,
                vol_mgr,
                vol_osd,
                vol_rgw,
                vol_config,
                // Container sets
                mon_containerSet,
                mgr_containerSet,
                osd_containerSet,
                rgw_containerSet,
                init_containerSet,
                // Services
                mon_service,
                mgr_service,
                osd_service,
                rgw_service,
            ])
    },
}
