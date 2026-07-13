The image-to-text service uses an OpenAI-compatible vision endpoint.
It reuses the same `openai-credentials` Kubernetes secret as the
OpenAI LLM component. If you are not already using OpenAI as your
LLM, you must create this secret.

```bash
kubectl -n {{namespace}} create secret \
    generic openai-credentials \
    --from-literal=openai-token=OPENAI-TOKEN-HERE \
    --from-literal=openai-url=https://api.openai.com/v1
```

Set `openai-url` to point at any OpenAI-compatible endpoint serving
a vision model. If you are using the OpenAI API directly, the
default URL shown above is correct.
