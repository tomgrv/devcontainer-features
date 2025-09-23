#!/bin/bash
# @format

# Sample test case demonstrating how to test a specific PR workflow scenario
# This script can be used as a template for creating additional test cases

set -e

echo "==================================="
echo "Sample PR Workflow Test Case"
echo "==================================="
echo

# Test Case 1: Validate that a new feature follows the required structure
test_new_feature_structure() {
    local feature_name="sample-feature"
    local temp_dir="/tmp/test-feature-$$"
    
    echo "Testing new feature structure validation..."
    
    # Create a temporary feature directory structure
    mkdir -p "$temp_dir/src/$feature_name"
    
    # Create required files
    cat > "$temp_dir/src/$feature_name/devcontainer-feature.json" << 'EOF'
{
    "id": "sample-feature",
    "name": "Sample Feature",
    "description": "A sample feature for testing",
    "version": "1.0.0"
}
EOF

    cat > "$temp_dir/src/$feature_name/install.sh" << 'EOF'
#!/bin/bash
echo "Installing sample feature..."
EOF

    chmod +x "$temp_dir/src/$feature_name/install.sh"
    
    # Test validation
    if jq empty "$temp_dir/src/$feature_name/devcontainer-feature.json" 2>/dev/null; then
        echo "✓ Feature JSON is valid"
    else
        echo "✗ Feature JSON is invalid"
        cleanup_test
        return 1
    fi
    
    if [ -f "$temp_dir/src/$feature_name/install.sh" ] && [ -x "$temp_dir/src/$feature_name/install.sh" ]; then
        echo "✓ Install script exists and is executable"
    else
        echo "✗ Install script missing or not executable"
        cleanup_test
        return 1
    fi
    
    cleanup_test() {
        rm -rf "$temp_dir"
    }
    
    cleanup_test
    echo "✓ New feature structure test passed"
    return 0
}

# Test Case 2: Validate PR trigger conditions
test_pr_trigger_conditions() {
    echo "Testing PR trigger conditions..."
    
    # Check if validate.yml has correct triggers
    if grep -q "pull_request:" .github/workflows/validate.yml; then
        echo "✓ Validate workflow has pull_request trigger"
    else
        echo "✗ Validate workflow missing pull_request trigger"
        return 1
    fi
    
    # Check if our test workflow has correct triggers
    if grep -q "pull_request:" .github/workflows/pr-workflow-test.yml; then
        echo "✓ PR workflow test has pull_request trigger"
    else
        echo "✗ PR workflow test missing pull_request trigger"
        return 1
    fi
    
    echo "✓ PR trigger conditions test passed"
    return 0
}

# Test Case 3: Validate required status checks configuration
test_status_checks_configuration() {
    echo "Testing status checks configuration..."
    
    # Verify that the validate workflow includes feature validation
    if grep -q "devcontainers/action@v1" .github/workflows/validate.yml; then
        echo "✓ Validate workflow includes devcontainers action"
    else
        echo "✗ Validate workflow missing devcontainers action"
        return 1
    fi
    
    # Verify that our test workflow has job dependencies
    if grep -q "needs:" .github/workflows/pr-workflow-test.yml; then
        echo "✓ PR workflow test has job dependencies"
    else
        echo "✗ PR workflow test missing job dependencies"
        return 1
    fi
    
    echo "✓ Status checks configuration test passed"
    return 0
}

# Run all test cases
echo "Running sample test cases..."
echo

test_cases=0
passed_cases=0

# Test Case 1
test_cases=$((test_cases + 1))
if test_new_feature_structure; then
    passed_cases=$((passed_cases + 1))
fi
echo

# Test Case 2  
test_cases=$((test_cases + 1))
if test_pr_trigger_conditions; then
    passed_cases=$((passed_cases + 1))
fi
echo

# Test Case 3
test_cases=$((test_cases + 1))
if test_status_checks_configuration; then
    passed_cases=$((passed_cases + 1))
fi
echo

echo "==================================="
echo "Sample Test Results"
echo "==================================="
echo "Total test cases: $test_cases"
echo "Passed: $passed_cases"
echo "Failed: $((test_cases - passed_cases))"

if [ $passed_cases -eq $test_cases ]; then
    echo "✓ All sample test cases passed!"
    exit 0
else
    echo "✗ Some sample test cases failed"
    exit 1
fi