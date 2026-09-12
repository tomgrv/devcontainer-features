<!-- @format -->

# Scripting Feature

Ensures the repo has a standard root `setup.sh`: installs `zz_use` + the
common `zz_*` bundle from [`tomgrv/scripts`](https://github.com/tomgrv/scripts),
then execs the repo's `package.json` `"main"` field (falling back to a root
`main.sh`, or just stopping if neither exists), forwarding any args
through. This is the same `setup.sh` pattern used by
[`perspikapps/vps`](https://github.com/perspikapps/vps).

`setup.sh` is checked (and deployed or repaired if missing/stale) on every
container start, so a hand-edited or accidentally deleted `setup.sh`
self-heals back to the standard.

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/scripting:1": {}
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- add scripting
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add scripting
```

## Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-scripting
```

## Making setup.sh actually do something

`setup.sh` on its own only bootstraps `zz_use`; to have it run your repo's
own entrypoint, add a `"main"` field to your root `package.json`:

```json
{
    "main": "dispatch.sh"
}
```

or drop a root `main.sh`. Without either, `setup.sh` installs `zz_use` and
stops - which is a valid end state for a plain scripts library (see
[`tomgrv/scripts`](https://github.com/tomgrv/scripts)'s own `setup.sh`).
