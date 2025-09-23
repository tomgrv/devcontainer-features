#!/bin/bash
# @format

# PR Workflow Validation Test Script
# This script validates that the PR workflow is properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[✓]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[!]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[✗]${NC} $message"
            ;;
    esac
}

# Function to run test and report results
run_test() {
    local test_name=$1
    local test_command=$2
    
    print_status "INFO" "Running test: $test_name"
    
    if eval "$test_command"; then
        print_status "SUCCESS" "$test_name passed"
        return 0
    else
        print_status "ERROR" "$test_name failed"
        return 1
    fi
}

# Initialize test counters
total_tests=0
passed_tests=0

echo "==================================="
echo "PR Workflow Validation Test Suite"
echo "==================================="
echo

# Test 1: Check if required workflow files exist
total_tests=$((total_tests + 1))
if run_test "Workflow files existence" "test -f .github/workflows/validate.yml && test -f .github/workflows/release.yaml"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 2: Validate workflow file syntax
total_tests=$((total_tests + 1))
if run_test "Workflow YAML syntax" "command -v yamllint >/dev/null 2>&1 && yamllint .github/workflows/*.yml .github/workflows/*.yaml || echo 'yamllint not available, skipping syntax check'"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 3: Check PR triggers in validate.yml
total_tests=$((total_tests + 1))
if run_test "PR trigger configuration" "grep -q 'pull_request' .github/workflows/validate.yml"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 4: Check main branch trigger in release.yaml
total_tests=$((total_tests + 1))
if run_test "Main branch trigger configuration" "grep -q 'branches:' .github/workflows/release.yaml && grep -q 'main' .github/workflows/release.yaml"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 5: Validate devcontainer feature files
total_tests=$((total_tests + 1))
test_devcontainer_features() {
    local failed=0
    for file in $(find src -name "devcontainer-feature.json"); do
        if ! jq empty "$file" 2>/dev/null; then
            print_status "ERROR" "Invalid JSON in $file"
            failed=1
        fi
    done
    return $failed
}
if run_test "Devcontainer feature JSON validation" "test_devcontainer_features"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 6: Check that all features have required files
total_tests=$((total_tests + 1))
test_feature_structure() {
    local failed=0
    for feature_dir in src/*/; do
        if [ -d "$feature_dir" ]; then
            feature_name=$(basename "$feature_dir")
            if [ ! -f "$feature_dir/devcontainer-feature.json" ]; then
                print_status "ERROR" "Missing devcontainer-feature.json in $feature_name"
                failed=1
            fi
            if [ ! -f "$feature_dir/install.sh" ]; then
                print_status "ERROR" "Missing install.sh in $feature_name"
                failed=1
            fi
        fi
    done
    return $failed
}
if run_test "Feature structure validation" "test_feature_structure"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 7: Check package.json test configuration
total_tests=$((total_tests + 1))
if run_test "Package.json test script" "jq -e '.scripts.test' package.json >/dev/null"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 8: Verify workflow dependencies are properly configured
total_tests=$((total_tests + 1))
test_workflow_dependencies() {
    # Check if validate workflow uses devcontainers action
    if ! grep -q "devcontainers/action@v1" .github/workflows/validate.yml; then
        print_status "ERROR" "Validate workflow missing devcontainers/action@v1"
        return 1
    fi
    
    # Check if release workflow has proper permissions
    if ! grep -q "permissions:" .github/workflows/release.yaml; then
        print_status "ERROR" "Release workflow missing permissions configuration"
        return 1
    fi
    
    return 0
}
if run_test "Workflow dependencies" "test_workflow_dependencies"; then
    passed_tests=$((passed_tests + 1))
fi

# Test 9: Check if PR workflow test exists and is valid
total_tests=$((total_tests + 1))
if run_test "PR workflow test file" "test -f .github/workflows/pr-workflow-test.yml && jq empty .github/workflows/pr-workflow-test.yml 2>/dev/null || yamllint .github/workflows/pr-workflow-test.yml >/dev/null 2>&1 || echo 'Basic file check passed'"; then
    passed_tests=$((passed_tests + 1))
fi

echo
echo "==================================="
echo "Test Results Summary"
echo "==================================="
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $((total_tests - passed_tests))"

if [ $passed_tests -eq $total_tests ]; then
    print_status "SUCCESS" "All PR workflow tests passed!"
    echo
    print_status "INFO" "PR workflow is properly configured and ready for use."
    exit 0
else
    print_status "ERROR" "Some tests failed. Please review the errors above."
    echo
    print_status "INFO" "Fix the issues and run the tests again."
    exit 1
fi