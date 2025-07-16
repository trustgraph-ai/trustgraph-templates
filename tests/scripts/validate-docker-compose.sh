#!/bin/bash

# Docker Compose Schema Validation Script
# Validates that generated docker-compose files are syntactically correct

set -e

COMPOSE_FILE="$1"

if [ -z "$COMPOSE_FILE" ]; then
    echo "Usage: $0 <docker-compose-file>"
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: File not found: $COMPOSE_FILE"
    exit 1
fi

echo "Validating Docker Compose file: $COMPOSE_FILE"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "Warning: docker-compose not found, skipping validation"
    exit 0
fi

# Validate syntax
echo "Checking syntax..."
if docker-compose -f "$COMPOSE_FILE" config -q 2>/dev/null; then
    echo "✓ Docker Compose syntax is valid"
else
    echo "✗ Docker Compose syntax validation failed"
    docker-compose -f "$COMPOSE_FILE" config 2>&1 | head -10
    exit 1
fi

# Check for common issues
echo "Checking for common issues..."

# Check for missing required fields
if ! grep -q "services:" "$COMPOSE_FILE"; then
    echo "✗ Missing services field"
    exit 1
fi

# Check for valid service definitions
if grep -q "image:" "$COMPOSE_FILE" || grep -q "build:" "$COMPOSE_FILE"; then
    echo "✓ Services have image or build definitions"
else
    echo "✗ No services with image or build definitions found"
    exit 1
fi

echo "✓ Docker Compose file validation passed"
