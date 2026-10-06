To use Alibaba Cloud DashScope (Qwen models), you need an API key which must be provided in a Kubernetes secret.

```bash
kubectl -n {{namespace}} create secret \
    generic dashscope-credentials \
    --from-literal=dashscope-token=DASHSCOPE-TOKEN-HERE
```
