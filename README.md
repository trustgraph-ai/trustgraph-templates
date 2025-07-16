# TrustGraph Configuration Templates

TrustGraph configurator is a Python-based tool that generates deployment configurations for TrustGraph AI systems. It supports multiple deployment platforms and provides templated configurations with versioning support.

## Overview

The configurator uses Jsonnet templates to generate deployment configurations for various platforms including Docker Compose, Podman, and multiple Kubernetes environments. It packages the generated configurations into ZIP files containing all necessary deployment resources.

## Installation

The configurator is distributed as a Python package. To use it:

```bash
export PYTHONPATH=.
# or install the package
pip install -e .
```

## Usage

### List Available Configurations

To see all available templates and platforms:

```bash
scripts/tg-configurations-list
```

This will display:
- Available platforms (docker-compose, podman-compose, various Kubernetes options)
- Available templates with versions and stability status
- Latest version and latest stable version

### Generate Configuration

To generate a configuration package:

```bash
scripts/tg-configurator --template <template-name> --version <version> \
    --input config.json --output output.zip --platform <platform>
```

Example:
```bash
scripts/tg-configurator --template 1.1 --version 1.1.9 \
    --input config.json --output deployment.zip --platform docker-compose
```

### Configuration Service API

You can also run the configurator as a REST API service:

```bash
scripts/tg-config-svc
```

This starts a web service on port 8080 that provides:
- REST API endpoints for configuration generation
- Programmatic access to version information
- Web-based configuration generation

The service provides the same functionality as the command-line tool but through HTTP endpoints (see API Service section below for details).

### Command Line Options

- `-i, --input`: Input configuration file (default: config.json)
- `-o, --output`: Output ZIP file (default: output.zip)
- `-t, --template`: Template name (e.g., "1.1", "1.0", "0.23")
- `-v, --version`: Specific version to use
- `-p, --platform`: Target platform (default: docker-compose)
- `--latest`: Use the latest available version
- `--latest-stable`: Use the latest stable version

### Available Platforms

- `docker-compose`: Local Docker deployment using docker-compose
- `podman-compose`: Local Podman deployment using podman-compose
- `minikube-k8s`: Minikube Kubernetes cluster
- `gcp-k8s`: Google Cloud Kubernetes (GKE)
- `aks-k8s`: Azure Kubernetes Service (AKS)
- `eks-k8s`: AWS Elastic Kubernetes Service (EKS)
- `scw-k8s`: Scaleway Kubernetes

### Template Versions

- **1.1** (stable): MCP support and agent functionality upgrades
- **1.0** (stable): Production release with Flow API and Librarian
- **0.23** (alpha): Early release with dynamic flow processing
- **0.22** (stable): Dynamic configuration without system restart
- **0.21** (stable): Mistral API, LM Studio, multiple OCR options

## Python Architecture

### Module Structure

The `trustgraph_configurator` package consists of several key modules:

#### Core Modules

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

3. **index.py** (`Index` class)
   - Manages template and platform metadata
   - Reads from `templates/index.json`
   - Provides version sorting and comparison
   - Offers methods to get latest/stable versions

4. **api.py** (`Api` class)
   - REST API service for configuration generation
   - Endpoints for version information and generation
   - Validates input JSON before processing
   - Returns generated configurations as binary data

5. **service.py**
   - Simple wrapper to run the API service
   - Configures logging and starts the web server on port 8080

6. **run.py**
   - Command-line interface implementation
   - Argument parsing and validation
   - Reads input configuration and writes output ZIP

7. **list.py**
   - Command-line tool to list available configurations
   - Displays platforms, templates, and versions in tabular format

### How Components Interact

```
User Input (config.json) 
    ↓
run.py (CLI) or api.py (REST)
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

1. **Template Resolution**: The `Packager.fetch()` method implements a sophisticated file resolution system:
   - Special handling for `trustgraph/config.json` and `version.jsonnet`
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

### Configuration Flow

1. User provides a JSON configuration file
2. Packager validates and loads the appropriate template version
3. Generator processes Jsonnet templates with the configuration
4. Platform-specific resources are added (Grafana dashboards, Prometheus config)
5. Everything is packaged into a ZIP file for deployment

### API Service

The REST API service (`tg-config-svc`) provides programmatic access to the configurator functionality. Start the service with:

```bash
scripts/tg-config-svc
```

The service runs on port 8080 and provides the following endpoints:

```
POST /api/generate/{platform}/{template}  # Generate configuration
GET /api/latest                          # Get latest version info
GET /api/latest-stable                   # Get latest stable version info
GET /api/versions                        # List all available versions
```

Example usage:
```bash
# Generate configuration via API
curl -X POST http://localhost:8080/api/generate/docker-compose/1.1 \
  -H "Content-Type: application/json" \
  -d @config.json \
  --output deployment.zip
```

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

## Error Handling

The configurator includes error handling for:
- Missing or invalid templates
- Malformed input JSON
- File resolution failures
- Platform-specific generation errors

Errors are logged with appropriate context for debugging.