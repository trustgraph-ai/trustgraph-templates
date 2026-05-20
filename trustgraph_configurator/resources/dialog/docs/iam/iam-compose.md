TrustGraph 2.4 introduces IAM (Identity and Access Management) for API and UX authentication. You must configure a bootstrap token to enable initial access. Set the `IAM_BOOTSTRAP_TOKEN` environment variable before starting the deployment. The token must have a `tg_` prefix to be recognised as an API token.

```
IAM_BOOTSTRAP_TOKEN=tg_your-secret-token-here
```
