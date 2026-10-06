To use OpenAI APIs, you need an API token which must be provided in a Kubernetes secret.

To use a custom OpenAI-compatible endpoint, include the `openai-url` literal with the base URL including the `/v1` path.

```bash
kubectl -n {{namespace}} create secret \
    generic openai-credentials \
    --from-literal=openai-token=OPENAI-TOKEN-HERE \
    --from-literal=openai-url=http://your-endpoint:7000/v1
```
