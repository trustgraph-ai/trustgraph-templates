To use Zhipu AI (GLM models), you need an API key which must be provided in a Kubernetes secret.

```bash
kubectl -n {{namespace}} create secret \
    generic glm-credentials \
    --from-literal=glm-token=GLM-TOKEN-HERE
```
