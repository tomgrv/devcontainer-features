<!-- @format -->

# pecl

## Description

Use this feature when an agent needs to install or manage PHP extensions from PECL in the dev container.

## Commands

- `pecl install <extension>` - Install a PHP extension from PECL.
- `pecl list` - List installed PECL extensions.
- `pecl info <extension>` - Show metadata/details for an extension.
- `php -m` - List loaded PHP modules to verify extension activation.
- `php --ri <extension>` - Print runtime info for an activated extension.

## Use For

- Installing required PHP extensions declared by project dependencies.
- Enabling extension support needed by tests or runtime.
- Standardizing extension setup through feature configuration.

## Do Not Use For

- Laravel workflow automation (use `larasets`).
- General system utility setup (use `common-utils`).

## Agent Guidance

- Install only extensions required by the project/task.
- Keep extension configuration explicit and reproducible.
- Validate PHP environment compatibility after extension changes.
