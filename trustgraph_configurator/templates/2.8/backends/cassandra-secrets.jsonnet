// Shared Cassandra connection secrets. Deploys nothing: just the
// ENV_VAR -> secret-key map (empty by default = self-hosted, no auth) and the
// helper that turns it into engine env secrets.
//
// Included by each Cassandra backend (cassandra, cassandra-cluster,
// cassandra-external) so these hooks always land in the merged config when a
// backend is present. Consumers (control, triples, rows) then read
// $["cassandra-env-secrets"] / $["cassandra-secrets"] straight off the merge -
// they don't import this file.

{

    // ENV_VAR -> secret-key map. Empty => self-hosted (host "cassandra", no
    // auth). cassandra-external populates it; +:: so component order in the
    // config list never clobbers it.
    "cassandra-secrets" +:: {},

    // Build engine env secrets from the map, or null when empty. Consumers call
    // this to attach the secrets to their container and to decide whether to
    // omit the cassandra_host param (external mode lets CASSANDRA_HOST win).
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
