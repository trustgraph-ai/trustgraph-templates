// Control-plane processors: flow orchestration and librarian service.

local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local garage = import "backends/garage.jsonnet";
local cassandra = import "backends/cassandra.jsonnet";

{

    "control" +: {

        "cpu-limit":: "0.5",
        "cpu-reservation":: "0.1",
        "memory-limit":: "256M",
        "memory-reservation":: "256M",

        local logLevel = $.parameters["log-level"],

        create:: function(engine)

            local librarianParams = {
                 id: "librarian",
                 object_store_endpoint: url.object_store,
                 object_store_access_key: $.garage["access-key"],
                 object_store_secret_key: $.garage["secret-key"],
                 object_store_region: $.garage.region,
            } + $["pub-sub-params"];

            local init = "trustgraph.bootstrap.initialisers";

            local initialisers = [
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
                                } + $["pub-sub-params"],
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
                                class: "trustgraph.bootstrap.bootstrapper.Processor",
                                "params": {
                                    "id": "bootstrap",
                                    "initialisers": initialisers,
                                } + $["pub-sub-params"]
                            }
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

            local memoryLimit = self["memory-limit"];
            local memoryReservation = self["memory-reservation"];

            local container =
                engine.container("control")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "processor-group",
                        "--log-level",
                        logLevel,
                        "-c",
                        "/etc/trustgraph/launch/launch.yaml"
                    ])
                    .with_volume_mount(
                        cfgVol, "/etc/trustgraph/launch/"
                    )
                    .with_volume_mount(
                        templateVol, "/etc/trustgraph/template/"
                    )
                    .with_limits(self["cpu-limit"], memoryLimit)
                    .with_reservations(
                        self["cpu-reservation"],
                        memoryReservation
                    );

            local containerSet = engine.containers(
                "control", [ container ]
            );

            local service =
                engine.internalService(containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                cfgVol,
                containerSet,
                service,
            ])

    }

// Garage and Cassandra are used by the Librarian
} + garage + cassandra

