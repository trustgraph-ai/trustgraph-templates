# Renderers

Each file in this directory is a top-level jsonnet program invoked by the
Python `Packager`. Given a config list plus an engine target, a renderer
emits the artifact for that target — docker-compose YAML, a k8s resource
list, the runtime `trustgraph/config.json`, or the collection of
`launch/*/launch.yaml` files shipped alongside the deployment.

## Pipeline

```
  config.json (list of {name, parameters})
        │
        ▼
  decode-config.jsonnet
        │   fold each config entry over a `base + components[name]`
        │   object, calling that object's `with_params(entry.parameters)`.
        │   The result is `patterns`: a merged object where each visible
        │   sub-field is a component instance carrying a `create(engine)`
        │   method plus any hidden `parameters +::` defaults.
        ▼
  patterns  ─────────────────────────────────────────────┐
        │                                                 │
        ▼                                                 ▼
  renderer invokes create(engine) on each             tg-configuration
  visible sub-object, with a target-specific          renderer reads
  engine (docker-compose, k8s, noop, collecting).     patterns.configuration
        │                                                 │
        ▼                                                 ▼
  target-shaped output                              trustgraph/config.json
  (docker-compose.yaml, k8s resource list,
   launch.yaml files, ...)
```

## Shared helpers

- **`decode-config.jsonnet`** — the fold that builds `patterns`. Every
  renderer imports this and calls `decode(config)`. The `base` object it
  defines supplies a default `with_params` (fold each key into a hidden
  top-level field); the `override` component in `components.jsonnet`
  replaces that default with a passthrough into `parameters +::`.

## The renderers

| File | Output | How it traverses `patterns` |
|------|--------|---|
| `config-to-docker-compose.jsonnet` | compose spec | `std.foldl(state + p.create(engine), std.objectValues(patterns), {})` |
| `config-to-podman-compose.jsonnet` | compose spec (podman) | same shape, same engine |
| `config-to-{aks,eks,gcp,minikube,ovh,scw}-k8s.jsonnet` | k8s resource list | `engine.package(patterns)` (the k8s engines own their own walk) |
| `config-to-noop.jsonnet` | empty-ish resources | same foldl shape, noop engine |
| `config-to-additionals.jsonnet` | list of `{path, content}` | runs `create` against a *collecting* engine that captures `configVolume` parts instead of producing container specs — this is how the `launch/*/launch.yaml` files get written |
| `config-to-tg-configuration.jsonnet` | `trustgraph/config.json` | reads `patterns.configuration.configuration` directly, no engine walk |

## Gotchas to know about

1. **`std.objectValues(patterns)` severs siblings.** Inside a component's
   `create`, `self` is only the sub-object the renderer extracted. Reads
   like `$.parameters["foo"]` still work because `$` follows merges, but
   there's no path back up from `self` to sibling components. The
   `parameters +::` / `override` pattern exists specifically to route
   tunables through the top-level object so they survive extraction.

2. **Every visible field of `patterns` must have a `create::` method**,
   except `configuration` (read directly by the tg-configuration
   renderer) and hidden `parameters` / `log-level` etc. The compose
   renderers call `.create` unconditionally, so a visible-but-createless
   sub-object crashes with "Field does not exist: create". The
   additionals renderer guards with `std.objectHasAll(p, 'create')`; the
   compose renderers deliberately don't, to surface the bug loudly.

3. **`$` is the merged root, resolved at eval time.** Works across
   imports and merges, *does not* follow `objectValues` extraction —
   see #1.
