# TrustGraph Configuration Templates

TrustGraph configurator is a Python-based tool that generates deployment configurations for TrustGraph AI systems. It supports multiple deployment platforms and provides templated configurations with versioning support.

## Overview

The configurator uses Jsonnet templates to generate deployment configurations for various platforms including Docker Compose, Podman, and multiple Kubernetes environments. It packages the generated configurations into ZIP files containing all necessary deployment resources.

The configuration service that hosts this as a REST API is in the separate [config-svc](https://github.com/trustgraph-ai/config-svc) repository, which depends on this package.

## Configuration Process

The TrustGraph configuration system uses a multi-stage pipeline to generate deployment packages:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Dialog Flow    │     │    JSONata      │     │  Configuration  │     │   Deployment    │
│  Configuration  │────▶│    Transform    │────▶│     Service     │────▶│    Package      │
│                 │     │                 │     │                 │     │                 │
│ (state object)  │     │ (config object) │     │   (templates)   │     │   (ZIP file)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
        │
        │               ┌─────────────────┐     ┌─────────────────┐
        └──────────────▶│  Documentation  │────▶│  Installation   │
                        │     Flow        │     │     Guide       │
                        └─────────────────┘     └─────────────────┘
```

### 1. Dialog Flow Configuration

The dialog flow file (`trustgraph-flow.yaml`) describes configuration steps in a technology-neutral way. A UI wizard walks users through these steps, collecting choices about platform, model provider, storage backends, and features. The output is a **state object** - a simple key/value map representing all user selections.

### 2. JSONata Transform

The JSONata transform file (`trustgraph-output.jsonata`) converts the state object into a **configuration object**. This object understands how to invoke TrustGraph templates and contains the structured parameters needed by the template system.

### 3. Configuration Service

The configuration service (hosted separately in [config-svc](https://github.com/trustgraph-ai/config-svc)) receives the configuration object, invokes the appropriate Jsonnet templates, and runs the package builder. The output is a **deployment package** - a ZIP file containing all deployment resources (docker-compose.yaml or Kubernetes manifests, plus supporting files).

### 4. Documentation Flow

The original state object can also be used with the documentation manifest (`trustgraph-docs.yaml`) to generate a customised **installation guide** based on the user's specific configuration choices.

## Installation

The configurator is distributed as a Python package:

```bash
pip install -e .
```

## Usage

### List Available Configurations

To see all available templates and platforms:

```bash
tg-show-config-params
```

This will display:
- Available platforms (docker-compose, podman-compose, various Kubernetes options)
- Available templates with versions and stability status
- Latest version and latest stable version

### Show Security Advisories

To see security advisories:

```bash
tg-show-advisories
```

To show only advisories affecting a specific version:

```bash
tg-show-advisories --version 2.8.3
```

### Generate Configuration

To generate a configuration package:

```bash
tg-build-deployment --template <template-name> \
    --input config.json --output output.zip --platform <platform>
```

Example:
```bash
tg-build-deployment --template 2.9 --latest-stable \
    --input config.json --output deployment.zip --platform docker-compose
```

#### Output to stdout

To output only the TrustGraph configuration:
```bash
tg-build-deployment --template 2.9 --latest-stable \
    --input config.json -O > trustgraph-config.json
```

To output only the platform resources (docker-compose.yaml or resources.yaml):
```bash
# For Docker Compose
tg-build-deployment --template 2.9 --latest-stable \
    --input config.json --platform docker-compose -R > docker-compose.yaml

# For Kubernetes
tg-build-deployment --template 2.9 --latest-stable \
    --input config.json --platform gcp-k8s -R > resources.yaml
```

### Command Line Options

- `-i, --input`: Input configuration file (default: config.json)
- `-o, --output`: Output ZIP file (default: output.zip)
- `-t, --template`: Template name (e.g., "2.10", "2.9", "2.8")
- `-v, --version`: Specific version to use
- `-p, --platform`: Target platform (default: docker-compose)
- `--latest`: Use the latest available version
- `--latest-stable`: Use the latest stable version
- `-l, --local-dir`: Enable local jsonnet components from specified directory
- `-O, --output-tg-config`: Output only TrustGraph configuration to stdout (no ZIP file)
- `-R, --output-resources`: Output only platform resources (docker-compose.yaml or resources.yaml) to stdout (no ZIP file)

### Available Platforms

- `docker-compose`: Local Docker deployment using docker-compose
- `podman-compose`: Local Podman deployment using podman-compose
- `minikube-k8s`: Minikube Kubernetes cluster
- `gcp-k8s`: Google Cloud Kubernetes (GKE)
- `aks-k8s`: Azure Kubernetes Service (AKS)
- `eks-k8s`: AWS Elastic Kubernetes Service (EKS)
- `scw-k8s`: Scaleway Kubernetes
- `ovh-k8s`: OVHCloud Kubernetes
- `ack-k8s`: Alibaba Cloud Kubernetes (ACK)

## Python Architecture

### Module Structure

The `trustgraph_configurator` package consists of several key modules:

1. **generator.py** (`Generator` class)
   - Processes Jsonnet templates using the `_jsonnet` library
   - Evaluates configuration snippets with custom import callbacks
   - Returns processed JSON configurations

2. **packager.py** (`Packager` class)
   - Main orchestrator for configuration generation
   - Handles template and resource file loading
   - Generates platform-specific deployment packages
   - Creates ZIP archives with all necessary files
   - Supports both Docker Compose and Kubernetes outputs
   - Dynamically generates `version.jsonnet` and `variant-id.jsonnet`

3. **index.py** (`Index` class)
   - Manages template, platform, and advisory metadata
   - Reads from `templates/index.json` and `templates/advisories.json`
   - Provides version sorting, comparison, and matching
   - Offers methods to get latest/stable versions and advisories
   - Serves dialog flow resources via `get_dialog_resource()`

4. **run.py**
   - Command-line interface implementation for `tg-build-deployment`
   - Argument parsing and validation
   - Reads input configuration and writes output ZIP

5. **list.py**
   - Command-line tool `tg-show-config-params`
   - Displays platforms, templates, and versions in tabular format

6. **show_advisories.py**
   - Command-line tool `tg-show-advisories`
   - Displays security advisories, optionally filtered by version

### How Components Interact

```
User Input (config.json) 
    ↓
run.py (CLI) or config-svc (REST)
    ↓
Packager (orchestrator)
    ├─→ Index (metadata/versions)
    ├─→ Generator (Jsonnet processing)
    └─→ Resource files (templates/)
         ↓
    Platform-specific generation
    (Docker Compose or Kubernetes)
         ↓
    ZIP archive (output.zip)
```

### Key Design Patterns

1. **Template Resolution**: The `Packager.fetch()` method implements a file resolution system:
   - Special handling for `trustgraph/config.json`, `version.jsonnet`, and `variant-id.jsonnet`
   - Fallback search paths for templates and resources
   - Version-specific template directories

2. **Platform Abstraction**: Different platforms are handled through:
   - Platform-specific Jsonnet templates (e.g., `config-to-docker-compose.jsonnet`)
   - Conditional logic in `Packager.generate()`
   - Unified output format (ZIP archives)

3. **Version Management**: The system supports:
   - Multiple template versions with different features
   - Stability levels (alpha, beta, stable)
   - Automatic version selection (latest/latest-stable)
   - Security advisories with version-range matching

## Metadata Files

Template metadata is in `trustgraph_configurator/templates/`:

- `index.json` — defines available templates, platforms, and statuses
- `advisories.json` — security advisories with affected version ranges

See `trustgraph_configurator/templates/README.md` for schema documentation.

## Output Structure

### Docker Compose Output

The generated ZIP file contains:
```
docker-compose.yaml      # Main deployment file
trustgraph/config.json   # TrustGraph configuration
grafana/                 # Grafana dashboards and provisioning
prometheus/              # Prometheus configuration
```

### Kubernetes Output

The generated ZIP file contains:
```
resources.yaml          # All Kubernetes resources in a single file
```

## Development

To extend or modify the configurator:

1. Templates are in `trustgraph_configurator/templates/<version>/`
2. Add new platforms by creating appropriate Jsonnet templates
3. Update `templates/index.json` for new versions
4. Resources (dashboards, configs) go in `trustgraph_configurator/resources/<version>/`
5. Dialog flow resources are in `trustgraph_configurator/resources/dialog/`:
   - `trustgraph-flow.yaml` - Dialog flow state machine
   - `trustgraph-output.jsonata` - State-to-config transform
   - `trustgraph-docs.yaml` - Documentation manifest
   - `docs/` - Markdown documentation fragments
6. Security advisories go in `trustgraph_configurator/templates/advisories.json`
