To use DeepSeek, you need an API key which must be provided in a Kubernetes secret.

```bash
kubectl -n {{namespace}} create secret \
    generic deepseek-credentials \
    --from-literal=deepseek-token=DEEPSEEK-TOKEN-HERE
```
