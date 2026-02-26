<!-- @format -->

# act

## Description

Use this feature when an agent needs to run GitHub Actions workflows locally with Nektos `act` inside a dev container.

## Use For

## Do Not Use For

## Agent Guidance

# act

## Description

Use this feature when an agent needs to run GitHub Actions workflows locally with Nektos `act` inside a dev container.

## Commands

- `act` - Run GitHub Actions workflows locally.
- `act -l` - List available workflows/jobs.
- `act <event>` - Run workflows for a specific GitHub event.
- `act-run` - Run repository wrapper flow around `act` defaults.
- `act-reset` - Reset local state/artifacts used by `act` wrapper scripts.

## Use For

- Running CI workflows locally before push.
- Reproducing workflow/job failures from GitHub Actions.
- Fast validation of workflow YAML changes.

## Do Not Use For

- Editing workflow logic unrelated to execution.
- Cloud deployment tasks.

## Agent Guidance

- Ensure Docker is available before running `act`.
- Prefer running the minimal target job first, then full workflow if needed.
- Use the feature version option when reproducibility is required.
