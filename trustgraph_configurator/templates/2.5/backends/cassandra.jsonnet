// Cassandra connection hooks shared by every consumer (control, triples,
// rows). This file deploys nothing - it only declares the wiring that
// consumers read. The self-hosted deployment lives in the separately-listed
// "cassandra" component (backends/cassandra-store.jsonnet); the managed path
// in "cassandra-external". One of those must be in the config to back
// Cassandra (config generation is owned upstream, so this isn't validated
// here).

{

    // ENV_VAR -> secret-key map. Empty by default, which means the self-hosted
    // store is in use: consumers talk to host "cassandra" with no auth. The
    // cassandra-external backend populates this map; +:: so component order in
    // the config list never clobbers it.
    "cassandra-secrets" +:: {},

    // Fixed helper (backends populate the map above, not this). Builds the
    // engine env secrets from the map, or null when empty. Consumers
    // (control / triples / rows) call this to attach the secrets to their
    // container and to decide whether to omit the cassandra_host param.
    "cassandra-env-secrets":: function(engine)
        local m = $["cassandra-secrets"];
        if std.length(m) > 0 then
            std.foldl(
                function(s, v) s.with_env_var(v, m[v]),
                std.objectFields(m),
                engine.envSecrets("cassandra")
            )
        else null,

}
