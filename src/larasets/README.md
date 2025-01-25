<!-- @format -->

# Laravel Settings

This feature provides a set of settings and utilities for working with Laravel projects.

## Example Usage

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/larasets:1": {}
}
```

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

## Utilities

The following utilities are included by default:

-   `art` - Run Laravel Artisan commands, locally or within the Laravel Sail environment if it is running.
-   `init` - Initialize the Laravel project by installing dependencies and setting up the environment.
-   `run` - Run npm scripts, locally or within the Laravel Sail environment if it is running.
-   `sail` - Run Laravel Sail commands.
-   `seed` - Run database migrations and seed the database.
-   `srv` - Start and manage PM2 processes for the Laravel application.

## Contributing

If you have a feature that you would like to add to this repository, please open an issue or submit a pull request.
