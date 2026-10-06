TrustGraph uses IAM (Identity and Access Management) for API and UX authentication. You must configure a bootstrap token before starting the deployment to set the first admin token. The token must have a `tg_` prefix to be recognised as a valid API key. TrustGraph CLI commands require `TRUSTGRAPH_TOKEN` to be set to this key. Additional auth keys can be provisioned through IAM.

```
export IAM_BOOTSTRAP_TOKEN="tg_my-secret-token"
export GF_SECURITY_ADMIN_PASSWORD="my-grafana-password"
```
