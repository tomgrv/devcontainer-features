<!-- @format -->

# larasets

## Description

Use this feature for Laravel-focused developer experience in dev containers, including artisan/sail wrappers, cache tasks, and PHP tooling presets.

## Commands

- `init` - Initialize Laravel project dependencies and environment defaults.
- `sail <...>` - Run Laravel Sail commands.
- `art <...>` - Run Artisan commands via local/Sail-aware wrapper.
- `run <...>` - Run npm scripts via local/Sail-aware wrapper.
- `srv <...>` - Run service process helpers (PM2-aware workflows).
- `seed` - Run migrations and seed database data.
- `fwd <...>` - Manage local-to-remote forwarding helper operations.
- `composer lint` - Run Pint linting flow for project code.
- `composer test` - Run Pest test suite.
- `composer upg` - Update Composer dependencies with project defaults.

## Use For

- Running Laravel commands through `art`, `sail`, `run`, `srv` wrappers.
- Bootstrapping Laravel local environment defaults.
- Automating cache refresh tasks for config/views/routes.
- Composer helper workflows tailored for Laravel monorepos.

## Do Not Use For

- Generic PHP extension installation (use `pecl`).
- Kubernetes/local cluster workflows (use `minikube`).

## Agent Guidance

- Prefer provided wrapper commands over raw command variants for portability.
- Use existing trigger-task patterns for cache-sensitive file changes.
- Keep Laravel defaults local/dev oriented unless explicitly asked for production behavior.
