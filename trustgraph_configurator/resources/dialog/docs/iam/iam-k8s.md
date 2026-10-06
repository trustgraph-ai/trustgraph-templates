TrustGraph uses IAM (Identity and Access Management) for API and UX authentication. You must configure a bootstrap token before deploying to set the first admin token. The token must have a `tg_` prefix to be recognised as a valid API key. TrustGraph CLI commands require `TRUSTGRAPH_TOKEN` to be set to this key. Additional auth keys can be provisioned through IAM.

Create the Kubernetes secrets before deploying:

```bash
kubectl -n {{namespace}} create secret \
    generic iam-bootstrap-token \
    --from-literal=iam-bootstrap-token="tg_my-secret-token"

kubectl -n {{namespace}} create secret \
    generic grafana-admin-password \
    --from-literal=grafana-admin-password="my-grafana-password"
```
