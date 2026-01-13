#!/bin/bash

# Kubernetes Resource Validation Script
# Validates that generated Kubernetes manifests are syntactically correct

set -e

K8S_FILE="$1"

if [ -z "$K8S_FILE" ]; then
    echo "Usage: $0 <kubernetes-manifest-file>"
    exit 1
fi

if [ ! -f "$K8S_FILE" ]; then
    echo "Error: File not found: $K8S_FILE"
    exit 1
fi

echo "Validating Kubernetes manifest: $K8S_FILE"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Warning: kubectl not found, skipping kubectl validation"
else
    # Check if cluster is accessible
    if kubectl cluster-info &> /dev/null; then
        # Validate syntax with kubectl
        echo "Checking syntax with kubectl..."
        if kubectl apply --dry-run=client -f "$K8S_FILE" > /dev/null 2>&1; then
            echo "✓ Kubernetes manifest syntax is valid"
        else
            echo "✗ Kubernetes manifest syntax validation failed"
            kubectl apply --dry-run=client -f "$K8S_FILE"
            exit 1
        fi
    else
        echo "⚠ kubectl validation skipped (no cluster available)"
    fi
fi

# Check for common issues
echo "Checking for common issues..."

# Check for valid YAML
if ! python3 -c "import yaml; yaml.safe_load(open('$K8S_FILE'))" 2>/dev/null; then
    echo "✗ Invalid YAML syntax"
    exit 1
fi

# Check for required Kubernetes fields
if ! grep -q "apiVersion:" "$K8S_FILE"; then
    echo "✗ Missing apiVersion field"
    exit 1
fi

if ! grep -q "kind:" "$K8S_FILE"; then
    echo "✗ Missing kind field"
    exit 1
fi

if ! grep -q "metadata:" "$K8S_FILE"; then
    echo "✗ Missing metadata field"
    exit 1
fi

echo "✓ Kubernetes manifest validation passed"