The image-to-text service uses an OpenAI-compatible vision endpoint.
It reuses the same credentials as the OpenAI LLM component. If you
are not already using OpenAI as your LLM, you must provide the
credentials in environment variables.

```
OPENAI_TOKEN=TOKEN-GOES-HERE
OPENAI_BASE_URL=https://api.openai.com/v1
```

Set `OPENAI_BASE_URL` to point at any OpenAI-compatible endpoint
serving a vision model. If you are using the OpenAI API directly,
the default URL shown above is correct.
