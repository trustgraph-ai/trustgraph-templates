#!/bin/bash

# TrustGraph Configurator Test Pipeline
# Comprehensive test suite for configuration generation and validation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$ROOT_DIR/tests"
CONFIGURATOR="$ROOT_DIR/scripts/tg-configurator"

# Test parameters
VERSIONS="0.21 0.22 1.0 1.1"
PLATFORMS="docker-compose podman-compose minikube-k8s gcp-k8s aks-k8s eks-k8s scw-k8s"
CONFIGS="minimal.json complex-rag.json multi-service.json cloud-aws.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Create temporary directory for test outputs
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "TrustGraph Configurator Test Pipeline"
echo "===================================="
echo "Running comprehensive configuration tests..."
echo

# Function to log test results
log_test() {
    local test_name=$1
    local result=$2
    local error_msg=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        if [ -n "$error_msg" ]; then
            echo "  Error: $error_msg"
        fi
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Function to test configuration generation
test_config_generation() {
    local version=$1
    local platform=$2
    local config=$3
    local test_name="$version/$platform/$config"
    
    echo -n "Testing configuration generation for $test_name... "
    
    # Test TrustGraph config generation
    if $CONFIGURATOR --template "$version" --platform "$platform" \
       --input "$TEST_DIR/configs/$config" --latest-stable -O \
       > "$TEMP_DIR/tg-config-$version-$platform-$config.json" 2>"$TEMP_DIR/error.log"; then
        
        # Test resource generation
        if $CONFIGURATOR --template "$version" --platform "$platform" \
           --input "$TEST_DIR/configs/$config" --latest-stable -R \
           > "$TEMP_DIR/resources-$version-$platform-$config.yaml" 2>>"$TEMP_DIR/error.log"; then
            
            log_test "$test_name generation" "PASS"
            return 0
        else
            log_test "$test_name generation" "FAIL" "Resource generation failed"
            cat "$TEMP_DIR/error.log" | sed 's/^/    /'
            return 1
        fi
    else
        log_test "$test_name generation" "FAIL" "TrustGraph config generation failed"
        cat "$TEMP_DIR/error.log" | sed 's/^/    /'
        return 1
    fi
}

# Function to test configuration validation
test_config_validation() {
    local version=$1
    local platform=$2
    local config=$3
    local test_name="$version/$platform/$config"
    
    local tg_config_file="$TEMP_DIR/tg-config-$version-$platform-$config.json"
    local resources_file="$TEMP_DIR/resources-$version-$platform-$config.yaml"
    
    # Skip if files don't exist (generation failed)
    if [ ! -f "$tg_config_file" ] || [ ! -f "$resources_file" ]; then
        return 1
    fi
    
    echo -n "Testing configuration validation for $test_name... "
    
    # Validate TrustGraph config is valid JSON
    if ! python3 -c "import json; json.load(open('$tg_config_file'))" 2>/dev/null; then
        log_test "$test_name TrustGraph config JSON" "FAIL" "Invalid JSON"
        return 1
    fi
    
    # Validate resources based on platform
    if [[ "$platform" == "docker-compose" || "$platform" == "podman-compose" ]]; then
        if "$SCRIPT_DIR/validate-docker-compose.sh" "$resources_file" > /dev/null 2>&1; then
            log_test "$test_name Docker Compose validation" "PASS"
        else
            log_test "$test_name Docker Compose validation" "FAIL" "Docker Compose validation failed"
            return 1
        fi
    else
        # Kubernetes platform
        if "$SCRIPT_DIR/validate-kubernetes.sh" "$resources_file" > /dev/null 2>&1; then
            log_test "$test_name Kubernetes validation" "PASS"
        else
            log_test "$test_name Kubernetes validation" "FAIL" "Kubernetes validation failed"
            return 1
        fi
    fi
    
    return 0
}

# Function to run tests for a specific combination
run_test_combination() {
    local version=$1
    local platform=$2
    local config=$3
    
    # Test configuration generation
    if test_config_generation "$version" "$platform" "$config"; then
        # Test configuration validation
        test_config_validation "$version" "$platform" "$config"
    fi
}

# Function to run all tests
run_all_tests() {
    echo -e "${BLUE}Phase 1: Configuration Generation Tests${NC}"
    echo "======================================="
    
    for version in $VERSIONS; do
        echo -e "${YELLOW}Testing template version $version${NC}"
        for platform in $PLATFORMS; do
            for config in $CONFIGS; do
                run_test_combination "$version" "$platform" "$config"
            done
        done
        echo
    done
}

# Function to run quick smoke tests
run_smoke_tests() {
    echo -e "${BLUE}Running Smoke Tests${NC}"
    echo "==================="
    
    # Test latest stable with minimal config on key platforms
    local latest_version="1.1"
    local key_platforms="docker-compose minikube-k8s"
    local minimal_config="minimal.json"
    
    for platform in $key_platforms; do
        run_test_combination "$latest_version" "$platform" "$minimal_config"
    done
}

# Function to run tests for a specific version
run_version_tests() {
    local version=$1
    echo -e "${BLUE}Testing Version $version${NC}"
    echo "======================"
    
    for platform in $PLATFORMS; do
        for config in $CONFIGS; do
            run_test_combination "$version" "$platform" "$config"
        done
    done
}

# Function to run tests for a specific platform
run_platform_tests() {
    local platform=$1
    echo -e "${BLUE}Testing Platform $platform${NC}"
    echo "========================="
    
    for version in $VERSIONS; do
        for config in $CONFIGS; do
            run_test_combination "$version" "$platform" "$config"
        done
    done
}

# Main function
main() {
    # Change to root directory
    cd "$ROOT_DIR"
    
    # Set PYTHONPATH for the configurator
    export PYTHONPATH="$ROOT_DIR"
    
    # Check if configurator exists
    if [ ! -f "$CONFIGURATOR" ]; then
        echo -e "${RED}Error: Configurator not found at $CONFIGURATOR${NC}"
        exit 1
    fi
    
    # Check if test configs exist
    for config in $CONFIGS; do
        if [ ! -f "$TEST_DIR/configs/$config" ]; then
            echo -e "${RED}Error: Test config not found: $TEST_DIR/configs/$config${NC}"
            exit 1
        fi
    done
    
    # Run tests based on command line argument
    case "${1:-all}" in
        "smoke")
            run_smoke_tests
            ;;
        "version")
            if [ -z "$2" ]; then
                echo "Usage: $0 version <version>"
                echo "Available versions: $VERSIONS"
                exit 1
            fi
            run_version_tests "$2"
            ;;
        "platform")
            if [ -z "$2" ]; then
                echo "Usage: $0 platform <platform>"
                echo "Available platforms: $PLATFORMS"
                exit 1
            fi
            run_platform_tests "$2"
            ;;
        "all"|"")
            run_all_tests
            ;;
        *)
            echo "Usage: $0 [all|smoke|version <ver>|platform <plat>]"
            echo "  all      - Run all tests (default)"
            echo "  smoke    - Run quick smoke tests"
            echo "  version  - Test specific version"
            echo "  platform - Test specific platform"
            exit 1
            ;;
    esac
    
    # Print summary
    echo
    echo "================================================"
    echo "Test Summary:"
    echo "  Total tests: $TOTAL_TESTS"
    echo -e "  Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "  Failed: ${RED}$FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
