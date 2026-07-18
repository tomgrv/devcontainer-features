<!-- @format -->

# Laravel Settings

This feature provides a set of settings and utilities for working with Laravel projects.

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/larasets:7": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add larasets
```

## Functional Coverage

- Configures Laravel environment variables.
- Ships a single environment-aware `🚀 Start` VS Code task plus optimize, migrate refresh, install, and IDE helper tasks.
- Starts the dev environment in order: optimize, serve, logs, queues, schedule, then smee.
- Supports Laravel Sail for containerized development (wrappers auto-target the Sail container when it is running).
- Loads secrets into `art`/`run`/`srv`/`serve`/`smee`/`dep` via `secret`: Doppler when available, else `.env` (`seed` inherits this through `art`).
- Installs necessary extensions and tools for Laravel development.

## Configuration

The following environment variables are set by default (`containerEnv`):

- `APP_DEBUG`: `true`
- `APP_ENV`: `local`
- `DB_CONNECTION`: `sqlite`
- `SAIL_XDEBUG_CONFIG`: `client_host=host.docker.internal idekey=vscode`
- `XDEBUG_CONFIG`: `client_host=localhost idekey=vscode`

### Options

- `doppler` (string, default empty): Doppler config name exported as
  `DOPPLER_CONFIG` for the `dep`/`secret` helpers. Leave empty to let Doppler
  resolve the config on its own — no personal config is shipped by default.

## Customizations

The feature also includes the following VS Code customizations:

- Extensions:
    - `aaron-bond.better-comments`
    - `alexcvzz.vscode-sqlite`
    - `bmewburn.vscode-intelephense-client`
    - `christian-kohler.npm-intellisense`
    - `davidanson.vscode-markdownlint`
    - `doppler.doppler-vscode`
    - `entexa.tall-stack`
    - `formulahendry.auto-close-tag`
    - `formulahendry.auto-rename-tag`
    - `gruntfuggly.triggertaskonsave`
    - `laravel.vscode-laravel`
    - `marabesi.php-import-checker`
    - `onecentlin.laravel-blade`
    - `pcbowers.alpine-intellisense`
    - `xdebug.php-debug`

- Deployed `.vscode/` stubs:
    - `tasks.json`: `🚀 Start` (env-aware full dev environment, started sequentially: optimize, serve, logs, queues, schedule, smee), Optimize, Refresh, Install, IDE Helper, and the save-triggered `art-cache-*` tasks.
    - `launch.json`: `Listen for XDebug` launch configuration (port 9003).
    - `mcp.json`: `laravel-boost` MCP server.
    - `settings.json`: Doppler autocomplete/hover defaults and `triggerTaskOnSave` cache refresh.

- Save-triggered cache refresh (`triggerTaskOnSave.tasks`, via `gruntfuggly.triggertaskonsave`):
    - `art-cache-config` (`art config:cache`): `**/config.php`, `config/*.php`, `.env`
    - `art-cache-views` (`art view:cache`): `packages/**/*.blade.php`
    - `art-cache-routes` (`art route:cache`): `**/[Rr]outes/*.php`

## Shell Utilities

The following utilities are included by default:

- `serve` - Start the app server, auto-selecting Laravel Sail or local PHP and binding `0.0.0.0:$APP_PORT` so forwarded ports work in Codespaces, dev containers, web, or local. Prompts for Sail only when the choice is ambiguous.
- `sail` - Run Laravel Sail commands.
- `seed` - Run database migrations and seed the database.
- `art` - Run Laravel Artisan commands, locally or within the Laravel Sail environment if it is running.
    - Use `art <...>` as you would do with `[php|sail] artisan <...>`
- `srv` - Start and manage PM2 processes, locally or within the Laravel Sail environment if it is running.
    - Use `srv <...>` as you would do with `<sail> npm run <...>`
- `fwd` - Manage port forwarding from `local` to `remote`.
- `run` - Run npm scripts, locally or within the Laravel Sail environment if it is running.
    - Use `run <...>` as you would do with `<sail> npm run <...>`
- `queues` - Stream the queue worker log, in Sail when running, else locally.
- `smee` - Forward smee.io webhook deliveries to the local app (`APP_URL`/`SMEE_TARGET`, channel `SMEE_CHANNEL`).
- `dep` - Run Deployer (`dep`) with the SSH key loaded and secrets injected via `secret`.
- `secret` - Run any command with the SSH agent loaded and secrets injected: Doppler when available, else `.env`, else run as-is.

`art`, `run`, `srv`, `serve`, `smee`, and `dep` all run their underlying command through `secret`, so the environment is loaded before it starts, without changing how you call them (`seed` gets this for free by calling `art`).

## Composer Utilities

The following utilities are added to root composer:

- `inst` - Install dependencies ignoring platform requirements.
- `link` - Configure local repositories.
- `lint` - Run Pint linter on staged files (--dirty by default).
- `lock` - Validate and update composer.lock with minimal changes.
- `req` - Require a package with all dependencies ignoring platform requirements.
- `reqdev` - Require a development package with all dependencies.
- `rmv` - Remove a package with all dependencies ignoring platform requirements.
- `test` - Run Pest tests.
- `test-coverage` - Run Pest tests with coverage.
- `upg` - Update dependencies with all dependencies ignoring platform requirements.

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
