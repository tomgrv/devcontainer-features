---
name: feature-larasets
description: Laravel developer experience helpers for artisan, sail, cache tasks, and PHP tooling presets.
---

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
- `serve` - Start the app server (env-aware: Sail vs local, binds 0.0.0.0:$APP_PORT).
- `dep <...>` - Run Deployer with SSH key and Doppler secrets injected.
- `secret <...>` - Run any command with SSH agent and Doppler secrets injected.
- `composer lint` - Run Pint linting flow for project code.
- `composer test` - Run Pest test suite.
- `composer upg` - Update Composer dependencies with project defaults.

## Use For

- Running Laravel commands through `art`, `sail`, `run`, `srv` wrappers.
- Bootstrapping Laravel local environment defaults via `init`.
- Starting the dev environment via the `🚀 Start` task / `serve` (Sail or local, any environment).
- Composer helper workflows tailored for Laravel monorepos.

## Do Not Use For

- Generic PHP extension installation (use `pecl`).
- Kubernetes/local cluster workflows (use `minikube`).

## Agent Guidance

- Prefer provided wrapper commands (`art`/`run`/`srv`) over raw `php artisan`/`npm`/`pm2` for Sail portability.
- Let the wrappers pick local vs Sail automatically — they detect a running Sail container.
- Keep Laravel defaults local/dev oriented unless explicitly asked for production behavior.
