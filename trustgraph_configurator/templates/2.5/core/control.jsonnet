// Control-plane processors: flow orchestration and librarian service.

local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local cassandra = import "backends/cassandra.jsonnet";

{

    parameters +:: {
        "control-cpu-limit": "0.5",
        "control-cpu-reservation": "0.1",
        "control-memory-limit": "256M",
        "control-memory-reservation": "256M",
        "control-replicas": 1,
    },

    // S3-compatible object store the librarian talks to. Fail-secure hooks,
    // empty by default: no params and no secrets means the librarian gets no
    // credentials and denies (fail-closed). An object-store backend component
    // populates one. control does NOT know which backends exist or how they
    // work - it just merges whatever was populated.
    //
    // Both use +:: (merge, not replace) so these empty defaults never clobber
    // a backend's value regardless of component order in the config list.
    //
    //   object-store-params  - map merged into the librarian's launch.yaml
    //                          params (an embedded store, e.g. garage, owns
    //                          its creds).
    //   object-store-secrets - map of ENV_VAR -> secret-key. control builds
    //                          the deploy-time env-var secrets from it (an
    //                          external store, e.g. object-store-s3). Empty
    //                          means no env secrets.
    "object-store-params" +:: {},
    "object-store-secrets" +:: {},

    "control" +: {

        local pars = $.parameters,

        local logLevel = pars["log-level"],
        local cpuLimit = pars["control-cpu-limit"],
        local cpuReservation = pars["control-cpu-reservation"],
        local memoryLimit = pars["control-memory-limit"],
        local memoryReservation = pars["control-memory-reservation"],
        local replicas = pars["control-replicas"],

        create:: function(engine)

            local envSecrets = engine.envSecrets("iam-bootstrap-token")
                .with_env_var("IAM_BOOTSTRAP_TOKEN", "token");

            // Object-store wiring comes entirely from the hooks above. A
            // backend populates one; if neither is set the librarian gets no
            // credentials and denies (fail-closed). control stays agnostic.
            // Build env secrets from the ENV_VAR -> key map; empty map (the
            // default, or an embedded backend) means no env secrets.
            local objectStoreEnv = $["object-store-secrets"];
            local objectStoreSecrets =
                if std.length(objectStoreEnv) > 0 then
                    std.foldl(
                        function(s, envVar)
                            s.with_env_var(envVar, objectStoreEnv[envVar]),
                        std.objectFields(objectStoreEnv),
                        engine.envSecrets("object-store")
                    )
                else null;

            // External Cassandra (cassandra-external backend) supplies the
            // librarian/iam/config/knowledge keyspaces' connection via env
            // secrets; null when self-hosted (host "cassandra", no auth).
            local cassandraSecrets = $["cassandra-env-secrets"](engine);

            local librarianParams = {
                 id: "librarian",
            } + $["object-store-params"] + $["pub-sub-params"];

            local init = "trustgraph.bootstrap.initialisers";

            local pulsarInit =
                if $["pub-sub-params"].pubsub_backend == "pulsar" then [
                    {
                        "class": "%s.PulsarTopology" % init,
                        "name": "pulsar-topology",
                        "flag": "v1",
                        "params": {
                            "admin_url": url.pulsar_admin,
                        }
                    }
                ] else [];

            local initialisers = pulsarInit + [
                {
                    "class": "%s.TemplateSeed" % init,
                    "name": "template-seed",
                    "flag": "v1",
                    "params": {
                        "config_file": "/etc/trustgraph/template/config.json",
                        "overwrite": false,
                    }
                },
                {
                    "class": "%s.WorkspaceInit" % init,
                    "name": "default-workspace",
                    "flag": "v1",
                    "params": {
                        "workspace": "default",
                        "source": "template",
                        "overwrite": false,
                    }
                },
                {
                    "class": "%s.DefaultFlowStart" % init,
                    "name": "default-flow",
                    "flag": "v1",
                    "params": {
                        "workspace": "default",
                        "flow_id": "default",
                        "blueprint": "everything",
                        "description": "Default",
                    }
                }
            ];

            local cfgVol = engine.configVolume(
                "control-launch-cfg", "launch/control",
		{
		    "launch.yaml": std.manifestYamlDoc({
                        processors: [
                            {
                                class: "trustgraph.librarian.Processor",
                                params: librarianParams,
                            },
                            {
                                class: "trustgraph.config.service.Processor",
                                params:  {
                                    id: "config-svc",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.flow.service.Processor",
                                params:  {
                                    id: "flow-svc",
                                } + $["pub-sub-params"] + $["pub-sub-admin-params"],
                            },
                            {
                                class: "trustgraph.cores.service.Processor",
                                params: {
                                    id: "knowledge",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.storage.knowledge.store.Processor",
                                params: {
                                    id: "kg-store",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.metering.Processor",
                                params: {
                                    id: "metering",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.metering.Processor",
                                params: {
                                    id: "metering-rag",
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.iam.service.Processor",
                                params: {
                                    id: "iam-svc",
                                    bootstrap_mode: "token",
                                    // Bootstrap token is set by
                                    // IAM_BOOTSTRAP_TOKEN
                                } + $["pub-sub-params"],
                            },
                            {
                                class: "trustgraph.bootstrap.bootstrapper.Processor",
                                "params": {
                                    "id": "bootstrap",
                                    "initialisers": initialisers,
                                } + $["pub-sub-params"]
                            },

                        ]
                    })
		}
            );

            local templateVol = engine.configVolume(
                "template-cfg", "trustgraph",
		{
                    // This is a virtual import?  Will be caught by the
                    // wrapper
		    "config.json": importstr "trustgraph/config.json",
		}
            );

            local baseContainer =
                engine.container("control")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch/launch.yaml"
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_volume_mount(
                        cfgVol, "/etc/trustgraph/launch/"
                    )
                    .with_volume_mount(
                        templateVol, "/etc/trustgraph/template/"
                    )
                    .with_limits(cpuLimit, memoryLimit)
                    .with_reservations(cpuReservation, memoryReservation);

            // Attach object-store and Cassandra env secrets only if a backend
            // populated them.
            local containerWithObjectStore =
                if objectStoreSecrets != null then
                    baseContainer.with_env_var_secrets(objectStoreSecrets)
                else baseContainer;

            local container =
                if cassandraSecrets != null then
                    containerWithObjectStore.with_env_var_secrets(cassandraSecrets)
                else containerWithObjectStore;

            local containerSet = engine.containers(
                "control", [ container ]
            ).with_replicas(replicas);

            local service =
                engine.internalService("control", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources(
                [
                    envSecrets,
                    cfgVol,
                    templateVol,
                    containerSet,
                    service,
                ]
                + (if objectStoreSecrets != null then [ objectStoreSecrets ]
                   else [])
                + (if cassandraSecrets != null then [ cassandraSecrets ]
                   else [])
            )

    }

// Cassandra is used by the Librarian.
} + cassandra

