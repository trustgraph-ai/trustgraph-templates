local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";

{

    with:: function(key, value)
        self + {
            ["tgi-" + key]:: value,
        },

    "tgi-max-output-tokens":: 1024,
    "tgi-temperature":: 0.0,

    "text-completion" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("tgi-credentials")
                .with_env_var("TGI_BASE_URL", "tgi-url");

            local container(x) =
                engine.container("text-completion-%d" % x)
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-tgi",
                        "-p",
                        url.pulsar,
                        "-x",
                        std.toString($["tgi-max-output-tokens"]),
                        "-t",
                        "%0.3f" % $["tgi-temperature"],
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet(x) = engine.containers(
                "text-completion-%d" % x, [ container(x) ]
            );

            local service(x) =
                engine.internalService(containerSet(x))
                .with_port(8080, 8080, "metrics");

            engine.resources([
                envSecrets
            ] + [
                containerSet(x)
                for x in std.range(0, $["text-completion-replicas"] - 1)
            ] + [
                service(x)
                for x in std.range(0, $["text-completion-replicas"] - 1)
            ])

    },

} + prompts

