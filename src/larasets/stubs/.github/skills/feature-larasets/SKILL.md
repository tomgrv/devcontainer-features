---
name: feature-larasets
description: Laravel developer experience helpers for artisan, sail, cache tasks, and PHP tooling presets.
---

<!-- @format -->

# larasets

## Description

Use this feature for Laravel-focused developer experience in dev containers, including artisan/sail wrappers, cache tasks, and PHP tooling presets.

## Commands

- `sail <...>` - Run Laravel Sail commands.
- `art <...>` - Run Artisan commands via local/Sail-aware wrapper.
- `run <...>` - Run npm scripts via local/Sail-aware wrapper.
- `srv <...>` - Run service process helpers (PM2-aware workflows).
- `seed` - Run migrations and seed database data.
- `fwd <...>` - Manage local-to-remote forwarding helper operations.
- `serve` - Start the app server (env-aware: Sail vs local, binds 0.0.0.0:$APP_PORT).
- `queues` - Stream queue/job worker logs (Sail-aware).
- `smee` - Forward smee.io webhook deliveries to the local app.
- `dep <...>` - Run Deployer with the SSH key loaded and secrets injected via `secret`.
- `secret <...>` - Run any command with the SSH agent loaded and secrets injected: Doppler when available, else `.env`.
- `composer lint` - Run Pint linting flow for project code.
- `composer test` - Run Pest test suite.
- `composer upg` - Update Composer dependencies with project defaults.

## Use For

- Running Laravel commands through `art`, `sail`, `run`, `srv` wrappers.
- Bootstrapping Laravel local environment defaults automatically on container create (`configure-sail`).
- Starting the dev environment via the `🚀 Start` task: optimize, serve, logs, queues, schedule, smee, in sequence (Sail or local, any environment).
- Composer helper workflows tailored for Laravel monorepos.
- `art`, `run`, `srv`, `serve`, `smee`, and `dep` all load environment via `secret` (Doppler, else `.env`) automatically; `seed` inherits this through `art`.

## Do Not Use For

- Generic PHP extension installation (use `pecl`).
- Kubernetes/local cluster workflows (use `minikube`).

## Agent Guidance

- Prefer provided wrapper commands (`art`/`run`/`srv`) over raw `php artisan`/`npm`/`pm2` for Sail portability.
- Let the wrappers pick local vs Sail automatically — they detect a running Sail container.
- Keep Laravel defaults local/dev oriented unless explicitly asked for production behavior.
