# Helm Chart Engine — Design Approach

## Problem

The template system generates deployment configs for Docker Compose, Podman,
K8s (AKS/EKS/GCP/OVH/SCW/ACK/Minikube), and ACA. Helm is the standard
packaging format for Kubernetes, and users expect to `helm install` rather
than `kubectl apply -f resources.yaml`.

## Approach: Engine-Native Generation (Option A)

Add a Helm engine alongside the existing engines. The Jsonnet templates
already carry all the data; the Helm engine is a different rendering pass
that outputs a chart directory structure instead of a flat K8s List resource.

This fits the existing architecture: each engine implements the same
container/service/volume API and differs only in what `package::` emits.

## Architecture Context

The current pipeline:

```
config.json → decode-config.jsonnet → patterns → engine.package(patterns) → output
```

- **Renderers** (`renderers/config-to-{platform}.jsonnet`) wire a config to
  an engine and evaluate `engine.package(patterns)`.
- **Packager** (`packager.py`) invokes the renderer via gojsonnet, serialises
  the output (YAML/JSON), and zips it.
- **K8s engines** extend `k8s.jsonnet` and override `package::` to wrap
  resources in a `{apiVersion: "v1", kind: "List", items: [...]}` envelope
  plus platform-specific preamble (StorageClass, Namespace).
- **Parameters** flow from config JSON through `decode-config.jsonnet` into
  component `create::` methods, which read `$.parameters` and call engine
  factory methods.

## Phased Implementation

### Phase 1 — Static Helm Chart Packaging

A Helm engine that extends `k8s.jsonnet` where `package::` returns a dict
of `{filename: content}` pairs:

```
trustgraph/
  Chart.yaml
  values.yaml          (empty or minimal — no Go template params yet)
  templates/
    resources.yaml     (concrete K8s manifests, same as current k8s output)
```

#### Engine file: `engine/helm-k8s.jsonnet`

- Imports `k8s.jsonnet` as the base.
- Overrides `package::` to:
  1. Generate resources the same way the K8s variants do (flattenArrays of
     `p.create(self)`).
  2. Build `Chart.yaml` with name, version, appVersion from the template
     version.
  3. Wrap resources as a multi-document YAML string for
     `templates/resources.yaml`.
  4. Return `{ "Chart.yaml": ..., "values.yaml": ..., "templates/resources.yaml": ... }`.

#### Renderer: `renderers/config-to-helm-k8s.jsonnet`

Standard pattern — import engine, decode config, call `engine.package(patterns)`.

#### Packager changes (`packager.py`)

- Add `"helm-k8s"` to platform routing.
- New `generate_helm()` method that takes the dict output and writes each
  key as a file path within a chart directory in the zip.
- Output: a zip containing the chart directory, ready for
  `helm install ./trustgraph` or `helm package`.

#### Registration: `index.json`

Add `{"name": "helm-k8s", "description": "Helm chart for Kubernetes"}` to
the platforms list.

#### What this gives users

An installable Helm chart with `helm install trustgraph ./trustgraph`.
Resources are static (same as current K8s output), but the chart is a
standard Helm artifact that can be hosted in a chart repository, versioned,
and managed with Helm lifecycle commands (upgrade, rollback, uninstall).

### Phase 2 — Parameterised Values

Override engine factory methods so configurable fields emit Go template
references instead of literal values.

#### Value plumbing

The Helm engine wraps values that should be configurable:

```jsonnet
// Instead of emitting "700M" directly:
heap: "{{ .Values.cassandra.heap }}"
```

Meanwhile `values.yaml` carries the concrete defaults:

```yaml
cassandra:
  heap: "700M"
  memoryLimit: "1400M"
  peers: 2
```

The engine needs to know which parameters are Helm-configurable. Options:

1. **Explicit annotation** — components mark parameters as helm-exposed via
   a naming convention or a `helm::` hidden field. The engine checks this
   and emits either a literal or a Go template reference.

2. **All parameters become values** — every entry in `$.parameters` is
   automatically exposed in `values.yaml`, and the engine emits
   `{{ .Values.parameters.<key> }}` for each one. Simpler but produces a
   flat, less ergonomic values.yaml.

3. **Engine-side mapping** — the Helm engine carries a mapping from
   parameter keys to values.yaml paths. Components are unchanged; the
   engine substitutes at render time.

Option 2 is the simplest starting point. Option 1 gives the best UX but
requires touching component templates. Option 3 keeps components clean but
centralises knowledge in the engine.

#### What this gives users

```bash
helm install trustgraph ./trustgraph \
  --set cassandra.heap=1G \
  --set cassandra.peers=4 \
  --set control.cpuLimit=2.0
```

Standard Helm parameterisation, tab-completable with `helm show values`.

## Files to Create/Modify

| File | Action |
|------|--------|
| `engine/helm-k8s.jsonnet` | New — Helm engine extending k8s.jsonnet |
| `renderers/config-to-helm-k8s.jsonnet` | New — standard renderer |
| `templates/index.json` | Add helm-k8s platform |
| `trustgraph_configurator/packager.py` | Add generate_helm() method |

## Open Questions

- Should Phase 1 include a Namespace resource in the chart, or rely on
  `helm install -n trustgraph --create-namespace`?
- Should the chart include a StorageClass, or is that a cluster-admin
  concern outside the chart? (Current K8s variants include one.)
- For Phase 2, which parameter exposure strategy (1/2/3) gives the best
  balance of UX and maintainability?
- Should there be multiple Helm variants (helm-aks, helm-eks, etc.) or a
  single generic helm-k8s with StorageClass as a value?
