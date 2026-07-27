local images = import "values/images.jsonnet";

{

    parameters +:: {
        "loki-cpu-limit": "1.0",
        "loki-cpu-reservation": "0.5",
        "loki-memory-limit": "350M",
        "loki-memory-reservation": "350M",
    },

    "loki" +: {

        local pars = $.parameters,
        local cpuLimit = pars["loki-cpu-limit"],
        local cpuReservation = pars["loki-cpu-reservation"],
        local memoryLimit = pars["loki-memory-limit"],
        local memoryReservation = pars["loki-memory-reservation"],

        create:: function(engine)

            local vol = engine.volume("loki-data").with_size("20G");

            local cfgVol = engine.configVolume(
                "loki-cfg", "loki",
		{
		    "local-config.yaml": importstr "loki/local-config.yaml",
		}
            );

            local container =
                engine.container("loki")
                    .with_image(images.loki)
                    .with_user(10001)
                    .with_group(10001)
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation)
                    .with_port(3100, 3100, "http")
                    .with_volume_mount(cfgVol, "/etc/loki/")
                    .with_volume_mount(vol, "/loki");

            local containerSet = engine.containers(
                "loki", [ container ]
            );

            local service =
                engine.internalService("loki", containerSet)
                .with_port(3100, 3100, "http");

            engine.resources([
                cfgVol,
                vol,
                containerSet,
                service,
            ])

    },

}

