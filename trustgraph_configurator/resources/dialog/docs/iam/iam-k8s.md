TrustGraph 2.4 introduces IAM (Identity and Access Management) for API and UX authentication. You must configure a bootstrap token to enable initial access. The token must have a `tg_` prefix to be recognised as an API token.

Create the Kubernetes secret before deploying:

```bash
kubectl -n {{namespace}} create secret \
    generic iam-bootstrap-token \
    --from-literal=token=tg_your-secret-token-here
```
