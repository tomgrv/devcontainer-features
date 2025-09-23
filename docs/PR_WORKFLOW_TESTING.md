# PR Workflow Testing

This document describes the automated testing infrastructure for validating the pull request workflow in the devcontainer-features repository.

## Overview

The PR workflow testing ensures that:
- Pull requests trigger the expected CI/CD actions
- Required checks and status validations run for new PRs  
- PR merges are only allowed if tests and checks pass
- The overall workflow integration functions correctly

## Test Infrastructure

### 1. GitHub Actions Workflow (`pr-workflow-test.yml`)

The main test workflow automatically runs on:
- Pull request events (opened, synchronize, reopened)
- Pushes to main branch
- Manual dispatch

**Test Jobs:**
- `test-pr-triggers`: Validates PR trigger mechanisms
- `test-status-checks`: Verifies required status checks
- `test-merge-requirements`: Tests merge protection rules
- `test-workflow-integration`: Validates workflow dependencies

### 2. Local Test Script (`test-pr-workflow.sh`)

A comprehensive bash script for local validation that can be run with:

```bash
npm test
# or
npm run test:pr-workflow
# or
./test-pr-workflow.sh
```

**Test Coverage:**
- Workflow file existence and syntax
- PR trigger configuration  
- Branch protection setup
- Devcontainer feature validation
- Package.json script configuration
- Workflow dependency validation

## Test Categories

### Trigger Validation Tests
- ✅ PR events trigger validate.yml workflow
- ✅ Main branch pushes trigger release.yaml workflow
- ✅ Workflow dispatch works correctly

### Status Check Tests  
- ✅ Devcontainer feature validation runs
- ✅ Required workflow files exist
- ✅ JSON syntax validation passes
- ✅ Feature structure validation

### Merge Protection Tests
- ✅ All required jobs must pass before merge
- ✅ Status checks are enforced
- ✅ Branch protection rules work

### Integration Tests
- ✅ Workflow dependencies configured correctly
- ✅ Permissions set appropriately  
- ✅ Package.json scripts functional

## Running Tests

### Locally
```bash
# Run all PR workflow tests
npm test

# Run specific test types
npm run test:pr-workflow
npm run test:devcontainer

# Run with verbose output
./test-pr-workflow.sh
```

### In CI/CD
Tests automatically run on every pull request. All test jobs must pass before merging is allowed.

## Test Results

The test script provides colored output:
- 🔵 `[INFO]` - Informational messages
- ✅ `[✓]` - Test passed
- ⚠️ `[!]` - Warning (non-fatal)
- ❌ `[✗]` - Test failed (blocks merge)

### Sample Output
```
===================================
PR Workflow Validation Test Suite  
===================================

[INFO] Running test: Workflow files existence
[✓] Workflow files existence passed
[INFO] Running test: PR trigger configuration  
[✓] PR trigger configuration passed
...
===================================
Test Results Summary
===================================
Total tests: 9
Passed: 9
Failed: 0
[✓] All PR workflow tests passed!
```

## Workflow Files Validated

### `.github/workflows/validate.yml`
- Validates devcontainer-feature.json files
- Triggers on pull requests
- Uses devcontainers/action@v1

### `.github/workflows/release.yaml`  
- Publishes features and generates documentation
- Triggers on main branch pushes
- Requires proper permissions

### `.github/workflows/pr-workflow-test.yml`
- Comprehensive PR workflow validation
- Runs on PRs and main branch
- Tests all workflow components

## Contributing

When modifying the PR workflow:

1. Run tests locally first: `npm test`
2. Ensure all tests pass before submitting PR
3. Add new tests for new workflow features
4. Update documentation as needed

For more information, see the [main README](../README.md).