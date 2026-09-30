<!-- @format -->

# Man In The Middle SSL Gateway Handling Feature

A [Dev Container](https://containers.dev/) helper for developing inside a corporate network protected by SSL inspection (Zscaler & similar).

## Problem

SSL inspection tools act as a man-in-the-middle TLS proxy and replace server certificates with their own. This breaks tools like `curl`, `git`, `npm`, `pip`, and others that perform certificate validation, because the root CA is not trusted by default inside a container — and often not even on the host, which prevents Docker from pulling the base image and the devcontainer CLI from downloading features in the first place.

## What this feature does

- Installs the SSL inspection root CA certificate(s) found in `.devcontainer/.gateway/certs/*.pem` into the container system trust store (at build time via the provided Dockerfile stub, and at create time via `postCreateCommand` — reached through the workspace's own standard mount, no dedicated bind mount required).
- Exposes the system CA bundle path via environment variables consumed by common runtimes and tools (Node.js, Python, Git, curl, Composer).
- Installs a `gateway-curl` wrapper that transparently handles gateway redirect forms and cookie management, and diverts the system `curl` to it — on by default inside a container, opt-in on a host (see [Options](#options)).
- Provisions VS Code extensions from VSIX packages fetched with `curl` — pre-fetched into the image at build time, then installed by a background flow running in parallel with VS Code attaching — because the VS Code server downloads extensions with Node's own `http` stack, which the curl wrapper cannot help (see [VS Code extensions](#vs-code-extensions-behind-the-gateway)).
- Optionally prepares the **host** as well, so the devcontainer can actually be created behind the gateway (see [Host installation](#host-installation--get-ready-for-devcontainer-creation)).

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gateway:8": {}
}
```

Then create the certificate folder and drop your root CA into it:

```sh
mkdir -p .devcontainer/.gateway/certs
cp /path/to/your-root-ca.pem .devcontainer/.gateway/certs/gateway.pem
```

> The certificate itself is optional — everything degrades gracefully until you supply it. Certificates are picked up through the workspace's own standard mount, so the `certs` folder doesn't need to exist before the container is created; add it any time and re-run `configure-feature gateway` (or rebuild).
>
> The stub `devcontainer.json` deployed by [`add gateway`](#quick-install--console-recommended) additionally declares a dedicated bind mount to a fixed, workspace-layout-independent path — useful for non-standard workspaces, but opt-in and freely editable/removable in your own `devcontainer.json`. If you're running in a nested/docker-outside-of-docker setup and see `bind source path does not exist`, that dedicated mount is the one thing to remove — its `${localWorkspaceFolder}` source needs to be a path the Docker daemon itself can see, which a mounted `docker.sock` doesn't guarantee.

## Quick Install — console (recommended)

`add gateway` self-detects whether it's running on the **host** or **inside an already-running container** and installs `gateway-curl` accordingly either way (diverting the system `curl` by default in a container, opt-in on a host — see [Options](#options)):

```sh
npx tomgrv/devcontainer-features -- add gateway
# or, without node/npm:
curl -fsSL https://raw.githubusercontent.com/tomgrv/devcontainer-features/develop/setup.sh | sh -s -- add gateway
```

Run it **on the host**, from the root of your project, before creating the container: this deploys the `.devcontainer` stubs (including a Dockerfile that bakes the certificate into the image at build time), installs `gateway-curl` on the host, and on Debian-based Linux/WSL installs the certificate into the host trust store when present. For other hosts, use the manual steps below.

## Quick Install — npm

```sh
npm install --save-dev @tomgrv/devcontainer-features-gateway
```

## Options

| Option        | Type    | Default | Description                                                                                                                    |
| ------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `replaceCurl` | boolean | `true`  | Divert the system `curl` to the `gateway-curl` wrapper inside the container (the real binary is kept as `curl.real`)           |
| `vsix`        | string  | `""`    | VS Code extensions (`publisher.name[@version]`, comma or space separated) to download with `curl` into the image at build time |

## Host installation — get ready for devcontainer creation

Declaring the feature in `devcontainer.json` is not always sufficient: the **host** needs to trust the gateway root CA too, otherwise `docker pull`, the devcontainer feature downloads, and any build-time HTTPS traffic fail before your container even exists.

### Automated (Linux / WSL, Debian-based)

From the root of your project, on the host. Any `npx tomgrv/devcontainer-features --` call below can be replaced with the no-node/npm `curl` form shown in [Quick Install](#quick-install--console-recommended) — just swap `add gateway` in after `-s --`.

```sh
# 1. Deploy the stubs and install gateway-curl on the host
npx tomgrv/devcontainer-features -- add gateway

# 2. Drop your root CA in place (PEM format)
cp /path/to/your-root-ca.pem .devcontainer/.gateway/certs/gateway.pem

# 3. Re-run the configuration to install the certificate into the host trust store
npx tomgrv/devcontainer-features -- add gateway
```

The host system `curl` is **never replaced automatically**. To also divert the host `curl` to the wrapper:

```sh
GATEWAY_REPLACE_CURL=1 npx tomgrv/devcontainer-features -- add gateway
```

Restart Docker after installing the certificate so the daemon picks up the new trust store:

```sh
sudo systemctl restart docker
```

### Manual (other hosts)

- **macOS**: `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain your-root-ca.pem`, then restart Docker Desktop.
- **Windows**: `certutil -addstore -f ROOT your-root-ca.pem` (elevated prompt), then restart Docker Desktop. The `ukoloff.win-ca` VS Code extension (pre-configured in the stub) propagates Windows certificates to VS Code.
- **Docker registries behind the gateway**: if pulls still fail, also place the certificate in `/etc/docker/certs.d/<registry>/ca.crt`.

Once the host trusts the CA and the certificate sits in `.devcontainer/.gateway/certs/`, the repository is ready: **Reopen in Container** just works.

## How it works

| Context                                                                         | What `add gateway` does                                                                                                                                                             |
| ------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Host (optional, Debian-based)                                                   | Installs `gateway-curl`, leaves the system `curl` untouched unless `GATEWAY_REPLACE_CURL=1`, and (on Debian-based Linux/WSL) installs the CA into the host trust store when present |
| Inside a container (devcontainer feature build or an already-running container) | Installs `gateway-curl` and diverts the system `curl` to it, unless the `replaceCurl` option is set to `false`                                                                      |

## Availability during the OCI image build

Trusting the gateway root CA and diverting `curl` normally only happen at container-create time (`postCreateCommand`), which runs **after** the image is built — too late for any `RUN curl ...` in a custom Dockerfile, or for an earlier-ordered feature that fetches something over HTTPS during its own `install.sh`.

The `.gateway/Dockerfile` stub closes that gap: it bakes both the root CA trust and the `gateway-curl` diversion into the very first layer of the image, before any feature runs. The mechanics it runs (`install-certs-core.sh`, `install-curl-wrapper-core.sh`, `gateway-curl.sh`) live under `stubs/.devcontainer/.gateway/` and are the single source of truth: `configure-certs.sh`/`install-wrapper.sh` call the very same scripts from that same relative path at container-create time, rather than keeping a second copy at the feature root.

## Modified repository structure

```
.devcontainer/
├── devcontainer.json        # Dev Container configuration (references the feature + Dockerfile)
└── .gateway/
    ├── Dockerfile           # Bakes the certificate at image build time
    └── certs/
        ├── .gitignore       # Keeps your corporate CA out of the repository
        └── gateway.pem      # Gateway root CA certificate  ← YOU MUST SUPPLY THIS
```

## VS Code extensions behind the gateway

The VS Code server installs extensions itself, from the Marketplace, with Node's own `http` stack: it never goes through `curl`, so the `gateway-curl` wrapper can't answer the gateway's interception form on its behalf, and every extension download fails. Trusting the root CA (`NODE_EXTRA_CA_CERTS`) fixes TLS, not the form.

The feature works around it in two flows, both downloading the `.vsix` packages with `curl` (hence through `gateway-curl`) and installing them from disk with the server's own CLI, which then never has to reach the Marketplace:

1. **Build time (docker)** — extensions listed in the `vsix` option are fetched into the image, under `/usr/local/share/gateway/vsix/`:

    ```json
    "features": {
        "ghcr.io/tomgrv/devcontainer-features/gateway:8": {
            "vsix": "esbenp.prettier-vscode, ms-python.python@2024.2.1"
        }
    }
    ```

    Build-time failures (e.g. no root CA baked by the [Dockerfile stub](#availability-during-the-oci-image-build) yet) don't break the build: flow 2 retries.

2. **Container creation (parallel)** — `postCreateCommand` detaches `gateway-vsix sync`, so container creation never waits on it. It fetches every extension your `devcontainer.json` lists under `customizations.vscode.extensions` that the image doesn't already hold (into `~/.cache/gateway/vsix/`), waits for the VS Code server to show up (15 min max), then installs everything cached. Log: `/tmp/gateway-vsix.log`.

VS Code still attempts its own Marketplace install of the `devcontainer.json` extensions in the meantime: those attempts may fail with a notification until `gateway-vsix sync` has installed them — run **Developer: Reload Window** if one doesn't activate. The feature also preconfigures the server with `extensions.autoUpdate` / `extensions.autoCheckUpdates` turned off, so it doesn't keep hitting the Marketplace (and failing) afterwards.

The extension list is resolved recursively from the root `devcontainer.json`: its own `customizations.vscode.extensions`, then those of every feature it references and, in turn, of their `dependsOn` (each feature visited once). OCI features are read from their registry manifest (`dev.containers.metadata` annotation, anonymous pull token, fetched with `curl` too), local `./` features from disk. A `-publisher.name` entry anywhere removes that extension. A feature whose metadata can't be reached is skipped with a log line.

Manual use:

```sh
gateway-vsix fetch ~/.cache/gateway/vsix publisher.name[@version]... # download
gateway-vsix ids .devcontainer/devcontainer.json                     # list what devcontainer.json wants
gateway-vsix sync                                                    # fetch + wait for server + install
```

| Variable               | Purpose                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `GATEWAY_VSIX_URL`     | Download URL template with `{publisher}` `{name}` `{version}` placeholders (default: Visual Studio Marketplace)           |
| `GATEWAY_VSIX_DIR`     | Runtime download cache (default: `~/.cache/gateway/vsix`)                                                                 |
| `GATEWAY_VSIX_CURL`    | curl command (default: `gateway-curl` when on `PATH`, else `curl`)                                                        |
| `GATEWAY_VSIX_TIMEOUT` | Seconds `sync` waits for the VS Code server (default: `900`)                                                              |
| `GATEWAY_VSIX_CLI`     | VS Code server CLI to install with (default: newest `code-server` found under `~/.vscode-server`, insiders or Codespaces) |

For Open VSX (pinned versions only): `GATEWAY_VSIX_URL='https://open-vsx.org/api/{publisher}/{name}/{version}/file/{publisher}.{name}-{version}.vsix'`.

Alternative, when the **host** VS Code gets past the gateway (e.g. Windows with `ukoloff.win-ca`): set `"remote.downloadExtensionsLocally": true` in your local user settings, so the host downloads extensions and pushes them into the container.

## Environment variables set automatically

All variables point to the system CA bundle (`/etc/ssl/certs/ca-certificates.crt`), which includes the gateway root CA once installed:

| Variable              | Purpose                           |
| --------------------- | --------------------------------- |
| `NODE_EXTRA_CA_CERTS` | Node.js / npm TLS trust           |
| `REQUESTS_CA_BUNDLE`  | Python `requests` / pip TLS trust |
| `SSL_CERT_FILE`       | OpenSSL-based tools               |
| `CURL_CA_BUNDLE`      | curl TLS trust                    |
| `GIT_SSL_CAINFO`      | git TLS trust                     |
| `COMPOSER_CA_FILE`    | PHP Composer TLS trust            |

## How the curl wrapper works

When a request is intercepted by the gateway and answered with an authentication/acceptance form, the wrapper:

1. Detects the HTML form response from the gateway.
2. Parses and auto-submits the form fields.
3. Saves the resulting session cookies to `~/.gateway_cookies.txt`.
4. Re-issues the original request transparently.

All other requests — including anything the wrapper cannot intercept safely (`-I`, `-O`, `-T`, `-w`, multiple URLs, …) — are passed through to the real curl unchanged, preserving arguments, output destinations and exit codes.

Wrapper environment variables:

| Variable              | Purpose                                                           |
| --------------------- | ----------------------------------------------------------------- |
| `GATEWAY_COOKIE_FILE` | Path to the cookie jar (default: `~/.gateway_cookies.txt`)        |
| `GATEWAY_VERBOSE`     | Set to `1` to trace what the wrapper does (silent by default)     |
| `GATEWAY_MARKER`      | Pattern identifying the gateway form (default: `gateway.zscaler`) |

## Troubleshooting

**Certificate errors still occurring**
Verify that `gateway.pem` contains the correct root CA (not an intermediate or leaf certificate). You can inspect it with:

```sh
openssl x509 -in .devcontainer/.gateway/certs/gateway.pem -noout -subject -issuer
```

**Certificate added after the container was created**
Run `configure-feature gateway` inside the container (or rebuild it) to install the newly added certificate.

**Container creation fails with `bind source path does not exist` on the certs mount**
Only relevant if your `devcontainer.json` declares the optional dedicated `certs` bind mount (added by the `add gateway` stub). Either create `.devcontainer/.gateway/certs` on the host before creating the container, or — in a nested/docker-outside-of-docker setup, where `${localWorkspaceFolder}` isn't a path the Docker daemon itself can resolve — remove that `mounts` entry from `devcontainer.json` entirely; certificates are still picked up through the workspace's own standard mount.

**VS Code extensions fail to install**
Check `/tmp/gateway-vsix.log`, then re-run `gateway-vsix sync` in a terminal once the certificate is in place.

**curl wrapper causes issues**
Call `curl.real` directly to bypass the wrapper, set `replaceCurl` to `false` to keep the system curl untouched, or set `GATEWAY_VERBOSE=1` to see what the wrapper is doing.

## License

MIT
