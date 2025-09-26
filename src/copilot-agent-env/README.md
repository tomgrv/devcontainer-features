# GitHub Copilot Agent Environment

This feature preinstalls tools and dependencies for optimal GitHub Copilot agent performance in devcontainer environments.

## Installation

To install this feature, add it to your `devcontainer.json`:

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/copilot-agent-env:1": {}
}
```

## Options

| Option | Description | Type | Default Value |
| ------ | ----------- | ---- | ------------- |
| `languageServers` | Language servers to install for better code understanding | string | `typescript python rust go` |
| `developmentTools` | Essential development tools for code analysis | string | `curl git jq tree ripgrep fd` |
| `packageManagers` | Package managers for dependency installation | string | `npm pip cargo` |
| `enableLanguageSupport` | Install language-specific tooling and runtime support | boolean | `true` |

## What Gets Installed

### Development Tools
- **curl** - Command line tool for transferring data
- **git** - Version control system
- **jq** - JSON processor
- **tree** - Directory structure display
- **ripgrep** - Fast text search tool
- **fd** - Fast file finder

### Package Managers
- **npm** - Node.js package manager
- **pip** - Python package installer
- **cargo** - Rust package manager
- **composer** - PHP dependency manager (optional)

### Language Servers (when enabled)
- **TypeScript** - TypeScript language server and ESLint
- **Python** - Python LSP server with mypy
- **Rust** - Rust analyzer
- **Go** - Go language server (gopls)

## VS Code Extensions

The feature automatically installs these VS Code extensions for enhanced Copilot experience:

- `github.copilot` - GitHub Copilot
- `github.copilot-chat` - GitHub Copilot Chat
- `ms-vscode.vscode-json` - JSON language support
- `ms-python.python` - Python support
- `rust-lang.rust-analyzer` - Rust support
- `golang.go` - Go support
- `ms-vscode.vscode-typescript-next` - TypeScript support
- `bradlc.vscode-tailwindcss` - Tailwind CSS support
- `ms-vscode.vscode-node-azure-pack` - Node.js development pack

## Environment Setup

The feature sets up:
- **PATH updates** for language-specific tools
- **Useful aliases** for development workflows
- **Environment variables** for optimal agent performance
- **Terminal configuration** for better shell experience

## Usage Examples

### Basic Installation
```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/copilot-agent-env:1": {}
}
```

### Custom Tool Selection
```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/copilot-agent-env:1": {
        "languageServers": "typescript python",
        "developmentTools": "curl git jq ripgrep",
        "packageManagers": "npm pip"
    }
}
```

### Minimal Installation (no language servers)
```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/copilot-agent-env:1": {
        "enableLanguageSupport": false,
        "developmentTools": "curl git jq"
    }
}
```

## Why This Feature?

GitHub Copilot agents work best when they have access to:
1. **Language servers** for understanding code context and structure
2. **Development tools** for analyzing and processing code
3. **Package managers** for installing dependencies
4. **Proper environment setup** for consistent behavior

This feature ensures all these components are available and properly configured for optimal Copilot agent performance.

## Compatibility

This feature is compatible with:
- Ubuntu-based containers
- Alpine Linux containers
- Most Debian-based containers
- RedHat/CentOS containers (with yum)

## Contributing

If you need additional tools or language servers, please open an issue or submit a pull request.