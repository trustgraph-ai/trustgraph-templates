// External Cassandra (managed / secured cluster). Deploys nothing - it only
// populates control's cassandra-secrets hook so every Cassandra consumer
// (control, triples, rows) reads its connection settings from env-var secrets
// supplied at deploy time, and omits the cassandra_host param so those env
// vars take effect:
//
//   CASSANDRA_HOST     CASSANDRA_USERNAME
//   CASSANDRA_PASSWORD CASSANDRA_REPLICATION_FACTOR
//
// Wire these via a K8s Secret named "cassandra" (keys host / username /
// password / replication-factor), compose env, or the equivalent ACA secret
// refs. replication-factor isn't secret but rides the same env bundle for
// consistency.
//
// Mutually exclusive with cassandra-cluster - import one Cassandra backend.

local secrets = import "cassandra-secrets.jsonnet";

secrets + {
    "cassandra-secrets" +:: {
        CASSANDRA_HOST: "host",
        CASSANDRA_USERNAME: "username",
        CASSANDRA_PASSWORD: "password",
        CASSANDRA_REPLICATION_FACTOR: "replication-factor",
    },
}
