local base = import "base/base.jsonnet";
local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local prompts = import "prompts/mixtral.jsonnet";

{

    with:: function(key, value)
        self + {
            ["tgi-rag-" + key]:: value,
        },

    "tgi-rag-max-output-tokens":: 1024,
    "tgi-rag-temperature":: 0.0,

    "text-completion-rag" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("tgi-credentials")
                .with_env_var("TGI_BASE_URL", "tgi-url");

            local container(x) =
                engine.container("text-completion-rag-%d" % x)
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "text-completion-tgi",
                        "-p",
                        url.pulsar,
                        "--id",
                        "text-completion-rag",
                        "-x",
                        std.toString($["tgi-rag-max-output-tokens"]),
                        "-t",
                        "%0.3f" % $["tgi-rag-temperature"],
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet(x) = engine.containers(
                "text-completion-rag-%d" % x, [ container(x) ]
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

