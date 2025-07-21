# TrustGraph Configurator Test Suite

This test suite validates the correctness of TrustGraph configuration generation across all supported template versions and deployment platforms.

## Quick Start

Run smoke tests (quick validation):
```bash
./tests/scripts/test-all-platforms.sh smoke
```

Run all tests:
```bash
./tests/scripts/test-all-platforms.sh all
```

## Test Structure

```
tests/
├── configs/           # Test configuration files
│   ├── minimal.json          # Basic configuration
│   ├── complex-rag.json      # RAG with multiple stores
│   ├── multi-service.json    # Multiple services + monitoring
│   └── cloud-aws.json        # AWS Bedrock configuration
├── scripts/           # Test execution scripts
│   ├── test-all-platforms.sh     # Main test pipeline
│   ├── test-template-compilation.sh  # Template compilation tests
│   ├── validate-docker-compose.sh   # Docker Compose validation
│   └── validate-kubernetes.sh       # Kubernetes validation
├── golden/            # Reference configurations (future)
└── schemas/           # Configuration schemas (future)
```

## Test Scripts

### Main Test Pipeline
```bash
./tests/scripts/test-all-platforms.sh [all|smoke|version <ver>|platform <plat>]
```

- `all` - Run comprehensive tests (default)
- `smoke` - Run quick smoke tests for key combinations
- `version <ver>` - Test specific template version
- `platform <plat>` - Test specific platform

### Template Compilation Tests
```bash
./tests/scripts/test-template-compilation.sh [all|version <ver>|platform <plat>|config <conf>]
```

Tests that all templates compile without errors.

### Individual Validation Scripts
```bash
./tests/scripts/validate-docker-compose.sh <compose-file>
./tests/scripts/validate-kubernetes.sh <k8s-manifest>
```

## Test Configurations

### minimal.json
Basic configuration with OpenAI LLM and HuggingFace embeddings.

### complex-rag.json
RAG configuration with multiple storage backends (Qdrant, Neo4j, Cassandra).

### multi-service.json
Configuration with Ollama, FastEmbed, monitoring enabled.

### cloud-aws.json
AWS Bedrock configuration for cloud deployments.

## Template Versions Tested

- **0.21** - Mistral API, LM Studio, OCR options
- **0.22** - Dynamic configuration
- **1.0** - Flow API, Librarian (stable)
- **1.1** - MCP support, agent upgrades (stable)

## Platforms Tested

- docker-compose
- podman-compose
- minikube-k8s
- gcp-k8s
- aks-k8s
- eks-k8s
- scw-k8s

## Test Types

### 1. Configuration Generation Tests
- Validates that all template/platform/config combinations generate without errors
- Tests both TrustGraph config (-O) and resource files (-R)

### 2. Schema Validation Tests
- Docker Compose: Validates syntax with `docker-compose config`
- Kubernetes: Validates syntax with `kubectl apply --dry-run`
- JSON: Validates TrustGraph config is valid JSON

### 3. Template Compilation Tests
- Ensures all Jsonnet templates compile without syntax errors
- Tests template resolution and imports

## Running Tests

### Prerequisites
- Python 3.x with required dependencies
- Docker and docker-compose (for Docker Compose validation)
- kubectl (for Kubernetes validation)

### Environment Setup
```bash
export PYTHONPATH=/path/to/trustgraph-templates
cd /path/to/trustgraph-templates
```

### Example Test Runs
```bash
# Quick smoke test
./tests/scripts/test-all-platforms.sh smoke

# Test latest stable version
./tests/scripts/test-all-platforms.sh version 1.1

# Test Docker Compose platform
./tests/scripts/test-all-platforms.sh platform docker-compose

# Test template compilation only
./tests/scripts/test-template-compilation.sh all
```

## Interpreting Results

### Test Output
- ✓ Green checkmark = Test passed
- ✗ Red X = Test failed
- Error details shown for failed tests

### Exit Codes
- 0 = All tests passed
- 1 = Some tests failed

### Common Failures
- Template compilation errors = Jsonnet syntax issues
- Resource validation errors = Invalid Docker Compose/Kubernetes syntax
- JSON validation errors = Malformed TrustGraph configuration

## Adding New Tests

### New Test Configuration
1. Create new JSON file in `tests/configs/`
2. Add to `CONFIGS` variable in test scripts
3. Update this README

### New Platform Support
1. Add to `PLATFORMS` variable in test scripts
2. Update validation logic if needed
3. Add platform-specific validation script if required

## Continuous Integration

To integrate with CI/CD:
```bash
# In your CI pipeline
./tests/scripts/test-all-platforms.sh smoke
```

For comprehensive testing:
```bash
./tests/scripts/test-all-platforms.sh all
```

## Troubleshooting

### Common Issues
1. **PYTHONPATH not set**: Ensure `PYTHONPATH` includes the project root
2. **Missing dependencies**: Install required Python packages
3. **Docker/kubectl not found**: Install tools or tests will be skipped
4. **Permission errors**: Ensure test scripts are executable

### Debug Mode
Add `set -x` to any test script for detailed execution tracing.

### Manual Testing
```bash
# Test specific combination manually
./scripts/tg-configurator --template 1.1 --platform docker-compose --input tests/configs/minimal.json -O
```
