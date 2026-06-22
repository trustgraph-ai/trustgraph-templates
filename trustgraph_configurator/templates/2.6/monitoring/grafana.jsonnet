local images = import "values/images.jsonnet";
local loki = import "loki.jsonnet";

{

    parameters +:: {
        "grafana-admin-user":: "admin",
    },

    "prometheus" +: {
    
        create:: function(engine)

            local vol = engine.volume("prometheus-data").with_size("20G");

            local cfgVol = engine.configVolume(
                "prometheus-cfg", "prometheus",
		{
		    "prometheus.yml": $["prometheus-config"],
		}
            );

            local container =
                engine.container("prometheus")
                    .with_image(images.prometheus)
                    .with_user(65534)
                    .with_group(65534)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M")
                    .with_port(9090, 9090, "http")
                    .with_volume_mount(cfgVol, "/etc/prometheus/")
                    .with_volume_mount(vol, "/prometheus");

            local containerSet = engine.containers(
                "prometheus", [ container ]
            );

            local service =
                engine.internalService("prometheus", containerSet)
                .with_port(9090, 9090, "http");

            engine.resources([
                cfgVol,
                vol,
                containerSet,
                service,
            ])

    },

    "grafana" +: {

        local pars = $.parameters,
    
        create:: function(engine)

            local vol = engine.volume("grafana-storage").with_size("20G");

            local envSecrets = engine.envSecrets("grafana-secret")
                .with_env_var("GF_SECURITY_ADMIN_PASSWORD", "password");

            local provDashVol = engine.configVolume(
                "prov-dash", "grafana/provisioning/",
		{
		    "dashboard.yml":
                        importstr "grafana/provisioning/dashboard.yml",
		}
		
            );

            local provDataVol = engine.configVolume(
                "prov-data", "grafana/provisioning/",
		{
		    "datasource.yml":
                        importstr "grafana/provisioning/datasource.yml",
		}
		
            );

            local dashVol = engine.configVolume(
                "dashboards", "grafana/dashboards/",
		{
		    "overview-dashboard.json":
                        $["overview-dashboard"],
		    "log-dashboard.json":
                        importstr "grafana/dashboards/log-dashboard.json",
		}
		
            );

            local container =
                engine.container("grafana")
                    .with_image(images.grafana)
                    .with_user(472)
                    .with_group(472)
                    .with_env_var_secrets(envSecrets)
                    .with_environment({
                        GF_ORG_NAME: "trustgraph.ai",
                        GF_SECURITY_ADMIN_USER: pars["grafana-admin-user"],
                        GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH: "/var/lib/grafana/dashboards/overview-dashboard.json",
                        GF_ANALYTICS_REPORT_WHATS_NEW: "false",
                        GF_PANELS_DISABLE_NEWS_FEED: "true",
                        GF_NEWS_NEWS_FEED_ENABLED: "false",
                        GF_PLUGINS_EXCLUDE_APPS: "grafana-assistant-app",
                        GF_FEATURE_TOGGLES_ASSISTANT: "false",
                    })
                    .with_limits("1.0", "256M")
                    .with_reservations("0.5", "256M")
                    .with_port(3000, 3000, "grafana")
                    .with_volume_mount(vol, "/var/lib/grafana")
                    .with_volume_mount(
                        provDashVol, "/etc/grafana/provisioning/dashboards/"
                    )
                    .with_volume_mount(
                        provDataVol, "/etc/grafana/provisioning/datasources/"
                    )
                    .with_volume_mount(
                        dashVol, "/var/lib/grafana/dashboards/"
                    );

            local containerSet = engine.containers(
                "grafana", [ container ]
            );

            local service =
                engine.service("grafana", containerSet)
                .with_port(3000, 3000, "http")
                ;

            engine.resources([
                vol,
	        provDashVol,
	        provDataVol,
		dashVol,
                containerSet,
                service,
            ])

    },

} + loki

