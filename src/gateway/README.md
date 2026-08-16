<!-- @format -->

# Man In The Middle SSL Gateway Handling Feature

A [Dev Container](https://containers.dev/) helper for developing inside a corporate network protected by SSL inspection (Zscaler & similar).

## Problem

SSL inspection tools act as a man-in-the-middle TLS proxy and replace server certificates with their own. This breaks tools like `curl`, `git`, `npm`, `pip`, and others that perform certificate validation, because the root CA is not trusted by default inside a container — and often not even on the host, which prevents Docker from pulling the base image and the devcontainer CLI from downloading features in the first place.

## What this feature does

- Installs the SSL inspection root CA certificate(s) found in `.devcontainer/.gateway/certs/*.pem` into the container system trust store (at build time via the provided Dockerfile stub, and at create time via `postCreateCommand` — reached through the workspace's own standard mount, no dedicated bind mount required).
- Exposes the system CA bundle path via environment variables consumed by common runtimes and tools (Node.js, Python, Git, curl, Composer).
- Installs a `gateway-curl` wrapper that transparently handles gateway redirect forms and cookie management, and diverts the system `curl` to it — on by default inside a container, opt-in on a host (see [Options](#options)).
- Optionally prepares the **host** as well, so the devcontainer can actually be created behind the gateway (see [Host installation](#host-installation--get-ready-for-devcontainer-creation)).

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/gateway:7": {}
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

| Option        | Type    | Default | Description                                                                                                          |
| ------------- | ------- | ------- | -------------------------------------------------------------------------------------------------------------------- |
| `replaceCurl` | boolean | `true`  | Divert the system `curl` to the `gateway-curl` wrapper inside the container (the real binary is kept as `curl.real`) |

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

The `.gateway/Dockerfile` stub closes that gap: it bakes both the root CA trust and the `gateway-curl` diversion into the very first layer of the image, before any feature runs. The mechanics it runs (`_install-certs-core.sh`, `_install-curl-wrapper-core.sh`, `_gateway-curl.sh`) live under `stubs/.devcontainer/.gateway/` and are the single source of truth: `configure-certs.sh`/`install-wrapper.sh` call the very same scripts from that same relative path at container-create time, rather than keeping a second copy at the feature root.

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
Run `zz_feature -c gateway` inside the container (or rebuild it) to install the newly added certificate.

**Container creation fails with `bind source path does not exist` on the certs mount**
Only relevant if your `devcontainer.json` declares the optional dedicated `certs` bind mount (added by the `add gateway` stub). Either create `.devcontainer/.gateway/certs` on the host before creating the container, or — in a nested/docker-outside-of-docker setup, where `${localWorkspaceFolder}` isn't a path the Docker daemon itself can resolve — remove that `mounts` entry from `devcontainer.json` entirely; certificates are still picked up through the workspace's own standard mount.

**curl wrapper causes issues**
Call `curl.real` directly to bypass the wrapper, set `replaceCurl` to `false` to keep the system curl untouched, or set `GATEWAY_VERBOSE=1` to see what the wrapper is doing.

## License

MIT
