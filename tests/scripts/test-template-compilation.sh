#!/bin/bash

# Template Compilation Validation Test
# Tests that all template versions compile without errors across all platforms

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$ROOT_DIR/tests"
CONFIGURATOR="tg-configurator"

# Test parameters
VERSIONS="1.4 1.5 1.6"
PLATFORMS="docker-compose podman-compose minikube-k8s gcp-k8s aks-k8s eks-k8s scw-k8s ovh-k8s"
CONFIGS="minimal.json complex-rag.json multi-service.json cloud-aws.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Create temporary directory for test outputs
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "TrustGraph Configurator Template Compilation Test"
echo "================================================"
echo "Testing template compilation across all versions and platforms..."
echo

# Function to run a single test
run_test() {
    local version=$1
    local platform=$2
    local config=$3
    local test_name="$version/$platform/$config"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "Testing $test_name... "
    
    # Test TrustGraph config generation
    if $CONFIGURATOR --template "$version" --platform "$platform" \
       --input "$TEST_DIR/configs/$config" --latest-stable -O \
       > "$TEMP_DIR/tg-config-$version-$platform-$config.json" 2>"$TEMP_DIR/error.log"; then
        
        # Test resource generation
        if $CONFIGURATOR --template "$version" --platform "$platform" \
           --input "$TEST_DIR/configs/$config" --latest-stable -R \
           > "$TEMP_DIR/resources-$version-$platform-$config.yaml" 2>>"$TEMP_DIR/error.log"; then
            
            echo -e "${GREEN}PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            echo -e "${RED}FAIL${NC} (resource generation failed)"
            echo "Error output:"
            cat "$TEMP_DIR/error.log" | sed 's/^/  /'
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        echo -e "${RED}FAIL${NC} (TrustGraph config generation failed)"
        echo "Error output:"
        cat "$TEMP_DIR/error.log" | sed 's/^/  /'
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to test a specific version
test_version() {
    local version=$1
    echo -e "${YELLOW}Testing template version $version${NC}"
    echo "----------------------------------------"
    
    for platform in $PLATFORMS; do
        for config in $CONFIGS; do
            run_test "$version" "$platform" "$config"
        done
    done
    echo
}

# Function to test a specific platform
test_platform() {
    local platform=$1
    echo -e "${YELLOW}Testing platform $platform${NC}"
    echo "----------------------------------------"
    
    for version in $VERSIONS; do
        for config in $CONFIGS; do
            run_test "$version" "$platform" "$config"
        done
    done
    echo
}

# Function to test a specific config
test_config() {
    local config=$1
    echo -e "${YELLOW}Testing configuration $config${NC}"
    echo "----------------------------------------"
    
    for version in $VERSIONS; do
        for platform in $PLATFORMS; do
            run_test "$version" "$platform" "$config"
        done
    done
    echo
}

# Main test execution
main() {
    # Change to root directory
    cd "$ROOT_DIR"
    
    # Set PYTHONPATH for the configurator
    export PYTHONPATH="$ROOT_DIR"
    
    # Check if configurator exists
    if ! command -v "$CONFIGURATOR" &> /dev/null; then
        echo -e "${RED}Error: Configurator command not found: $CONFIGURATOR${NC}"
        echo -e "${YELLOW}Make sure trustgraph-configurator is installed (pip install -e .)${NC}"
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
        "version")
            if [ -z "$2" ]; then
                echo "Usage: $0 version <version>"
                echo "Available versions: $VERSIONS"
                exit 1
            fi
            test_version "$2"
            ;;
        "platform")
            if [ -z "$2" ]; then
                echo "Usage: $0 platform <platform>"
                echo "Available platforms: $PLATFORMS"
                exit 1
            fi
            test_platform "$2"
            ;;
        "config")
            if [ -z "$2" ]; then
                echo "Usage: $0 config <config>"
                echo "Available configs: $CONFIGS"
                exit 1
            fi
            test_config "$2"
            ;;
        "all"|"")
            # Run all tests
            for version in $VERSIONS; do
                test_version "$version"
            done
            ;;
        *)
            echo "Usage: $0 [all|version <ver>|platform <plat>|config <conf>]"
            echo "  all      - Run all tests (default)"
            echo "  version  - Test specific version"
            echo "  platform - Test specific platform"
            echo "  config   - Test specific configuration"
            exit 1
            ;;
    esac
    
    # Print summary
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
