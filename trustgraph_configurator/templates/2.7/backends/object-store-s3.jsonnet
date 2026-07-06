// External S3-compatible object store (AWS S3, Cloudflare R2, managed MinIO,
// etc.). Deploys nothing - it only populates control's object-store-secrets
// hook so the librarian reads every setting from env-var secrets supplied at
// deploy time. It sets no object-store-params, so launch.yaml stays free of
// object_store_* and the librarian falls through to its env-var path.
//
//   OBJECT_STORE_ENDPOINT    OBJECT_STORE_ACCESS_KEY
//   OBJECT_STORE_SECRET_KEY  OBJECT_STORE_REGION    OBJECT_STORE_USE_SSL
//
// Fail-secure: nothing is baked into the rendered config. If the secret /
// environment is not supplied at deploy, the librarian has no credentials and
// denies access. Wire these via a K8s Secret named "object-store" (keys
// endpoint / access-key / secret-key / region / use-ssl), compose env, or the
// equivalent ACA secret refs.
//
// Mutually exclusive with garage / garage-cluster - import exactly one object
// store backend.

// The map is ENV_VAR -> secret-key; control builds the env-var secrets from
// it (Secret named "object-store" with these keys).

{
    "object-store-secrets" +:: {
        OBJECT_STORE_ENDPOINT: "endpoint",
        OBJECT_STORE_ACCESS_KEY: "access-key",
        OBJECT_STORE_SECRET_KEY: "secret-key",
        OBJECT_STORE_REGION: "region",
        OBJECT_STORE_USE_SSL: "use-ssl",
    },
}
