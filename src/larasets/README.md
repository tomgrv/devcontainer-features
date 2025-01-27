<!-- @format -->

# Laravel Settings

This feature provides a set of settings and utilities for working with Laravel projects.

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/larasets:1": {}
}
```

## Functional Coverage

- Configures Laravel environment variables.
- Provides tasks for caching configuration, views, and routes.
- Supports Laravel Sail for containerized development.
- Installs necessary extensions and tools for Laravel development.

## Configuration

The following environment variables are set by default:

-   `APP_DEBUG`: `true`
-   `APP_ENV`: `local`
-   `LARAVEL_SAIL`: `1`
-   `DB_CONNECTION`: `sqlite`
-   `SAIL_XDEBUG_MODE`: `develop,debug`
-   `SAIL_XDEBUG_CONFIG`: `client_host=host.docker.internal idekey=vscode`
-   `XDEBUG_MODE`: `off`

## Customizations

The feature also includes the following VS Code customizations:

-   Extensions:

    -   `actboy168.tasks`
    -   `spmeesseman.vscode-taskexplorer`
    -   `gruntfuggly.triggertaskonsave`
    -   `entexa.tall-stack`
    -   `formulahendry.auto-rename-tag`
    -   `formulahendry.auto-close-tag`
    -   `marabesi.php-import-checker`
    -   `alexcvzz.vscode-sqlite`
    -   `bmewburn.vscode-intelephense-client`
    -   `onecentlin.laravel-blade`
    -   `xdebug.php-debug`
    -   `devsense.composer-php-vscode`
    -   `christian-kohler.npm-intellisense`
    -   `davidanson.vscode-markdownlint`
    -   `pcbowers.alpine-intellisense`
    -   `laravel.vscode-laravel`
    -   `aaron-bond.better-comments`

-   Settings:
    -   `triggerTaskOnSave.tasks`:
        -   `art-cache-config`: `**/config.php`, `config/*.php`, `.env`
        -   `art-cache-views`: `packages/**/*.blade.php`
        -   `art-cache-routes`: `**/[Rr]outes/*.php`

## Shell Utilities

The following utilities are included by default:

-   `init` - Initialize the Laravel project by installing dependencies and setting up the environment.
-   `sail` - Run Laravel Sail commands.
-   `seed` - Run database migrations and seed the database.
-   `art` - Run Laravel Artisan commands, locally or within the Laravel Sail environment if it is running.
    - Use `art <...>` as you would do with `[php|sail] artisan <...>`
-   `srv` - Start and manage PM2 processes, locally or within the Laravel Sail environment if it is running.
    - Use `srv <...>` as you would do with `<sail> npm run <...>`
-   `fwd` - Manage port forwarding form `local` to `remote`
-   `run` - Run npm scripts, locally or within the Laravel Sail environment if it is running.
    - Use `run <...>` as you would do with `<sail> npm run <...>`

## Composer Utilities

The following utilities are added to root composer:

-   `inst` - Install dependencies ignoring platform requirements.
-   `link` - Configure local repositories.
-   `lint` - Run Pint linter on staged files (--dirty by default).
-   `lock` - Validate and update composer.lock with minimal changes.
-   `req` - Require a package with all dependencies ignoring platform requirements.
-   `req-all` - Require a package across all packages managed by Lerna ignoring platform requirements.
-   `reqdev` - Require a development package with all dependencies.
-   `reqdev-all` - Require a development package across all packages managed by Lerna.
-   `rmv` - Remove a package with all dependencies ignoring platform requirements.
-   `rmv-all` - Remove a package across all packages managed by Lerna ignoring platform requirements.
-   `test` - Run Pest tests.
-   `test-coverage` - Run Pest tests with coverage.
-   `upg` - Update dependencies with all dependencies ignoring platform requirements.
-   `upg-all` - Update dependencies across all packages managed by Lerna ignoring platform requirements.

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
