local images = import "values/images.jsonnet";
local url = import "values/url.jsonnet";
local cassandra_hosts = "cassandra";

{

    parameters +:: {
        "store-graph-embeddings-replicas": 1,
        "query-graph-embeddings-replicas": 1,
        "store-doc-embeddings-replicas": 1,
        "query-doc-embeddings-replicas": 1,
    },

    local logLevel = $.parameters["log-level"],
    local pars = $.parameters,

    "pinecone-cloud":: "aws",
    "pinecone-region":: "us-east-1",

    "store-graph-embeddings" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("pinecone-api-key")
                .with_env_var("PINECONE_API_KEY", "pinecone-api-key");

            local container =
                engine.container("store-graph-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "ge-write-pinecone",
] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "store-graph-embeddings", [ container ]
            ).with_replicas(pars["store-graph-embeddings-replicas"]);

            local service =
                engine.internalService("store-graph-embeddings", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                containerSet,
                service,
            ])

    },

    "query-graph-embeddings" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("pinecone-api-key")
                .with_env_var("PINECONE_API_KEY", "pinecone-api-key");

            local container =
                engine.container("query-graph-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "ge-query-pinecone",
] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "query-graph-embeddings", [ container ]
            ).with_replicas(pars["query-graph-embeddings-replicas"]);

            local service =
                engine.internalService("store-graph-embeddings", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                containerSet,
                service,
            ])

    },

    "store-doc-embeddings" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("pinecone-api-key")
                .with_env_var("PINECONE_API_KEY", "pinecone-api-key");

            local container =
                engine.container("store-doc-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "de-write-pinecone",
] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "store-doc-embeddings", [ container ]
            ).with_replicas(pars["store-doc-embeddings-replicas"]);

            local service =
                engine.internalService("store-graph-embeddings", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                containerSet,
                service,
            ])

    },

    "query-doc-embeddings" +: {
    
        create:: function(engine)

            local envSecrets = engine.envSecrets("pinecone-api-key")
                .with_env_var("PINECONE_API_KEY", "pinecone-api-key");

            local container =
                engine.container("query-doc-embeddings")
                    .with_image(images.trustgraph_flow)
                    .with_command([
                        "de-query-pinecone",
] + $["pub-sub-args"] + [
                        "--log-level",
                        logLevel,
                    ])
                    .with_env_var_secrets(envSecrets)
                    .with_limits("0.5", "128M")
                    .with_reservations("0.1", "128M");

            local containerSet = engine.containers(
                "query-doc-embeddings", [ container ]
            ).with_replicas(pars["query-doc-embeddings-replicas"]);

            local service =
                engine.internalService("store-graph-embeddings", containerSet)
                .with_port(8000, 8000, "metrics");

            engine.resources([
                envSecrets,
                containerSet,
                service,
            ])


    }

}

