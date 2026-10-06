To use Near AI, you need an API token which must be provided in a Kubernetes secret.

```bash
kubectl -n {{namespace}} create secret \
    generic near-ai-credentials \
    --from-literal=near-ai-token=NEAR-AI-TOKEN-HERE
```
