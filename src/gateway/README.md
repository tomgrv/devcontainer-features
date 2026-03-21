<!-- @format -->

# Man In The Middle SSL Gateway Handling Feature

A [Dev Container](https://containers.dev/) helpêr for developing inside a corporate network protected by SSL inspection.

## Problem

SSL inspection tools acts as a man-in-the-middle TLS proxy and replaces server certificates with its own. This breaks tools like `curl`, `git`, `npm`, `pip`, and others that perform certificate validation, because the root CA is not trusted by default inside a container.

## What this feature does

- Installs the SSL inspection root CA certificate provided in `.devcontainer/.gateway/certs/gateway.pem` into the system trust store at build time.
- Exposes the certificate path via environment variables consumed by common runtimes and tools (Node.js, Python, Git, curl, Composer).
- Replaces the system `curl` binary (**locally** and in devcontainer) with a **wrapper script** (`gateway-curl`) that transparently handles gateway redirect forms and cookie management.

## Modified repository structure

```
.devcontainer/
├── devcontainer.json        # Dev Container configuration
├── create.sh                # postCreateCommand
├── start.sh                 # postStartCommand
└── .gateway/
    └── certs/
       └── gateway.pem      # Gateway root CA certificate  ← YOU MUST SUPPLY THIS
```

## Prerequisites

- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), **or** [GitHub Codespaces](https://github.com/features/codespaces).
- Docker (local) or a Codespaces-compatible environment.
- Your organisation's **root CA certificate** in PEM format.

## Setup

1. **Run the feature installer**

Declaring the feature in your `devcontainer.json` may not be sufficient as you would need to have the Zscaler certificate in place at build time.

To work around this, run the installer script manually in your terminal:

```sh
npx tomgrv/devcontainer-features gateway
```

2. **Add your root CA certificate**

    Export the root CA from your browser or system trust store and save it as:

    ```
    .devcontainer/.gateway/certs/gateway.pem
    ```

    > The certificate must be in **PEM format** (base64-encoded, begins with `-----BEGIN CERTIFICATE-----`).

3. **Customise `devcontainer.json`** (optional)

    Add or remove [Dev Container Features](https://containers.dev/features), VS Code extensions, forwarded ports, etc. to suit your project.

    Comes pre-configured with tomgrv's devcontainer features for Git utilities, Git hooks management, and semantic versioning with GitVersion.

4. **Open in Dev Container**
    - VS Code: open the repository folder and choose **Reopen in Container** when prompted.
    - GitHub Codespaces: click **Code → Create codespace on main**.

## Environment variables set automatically

| Variable              | Purpose                           |
| --------------------- | --------------------------------- |
| `NODE_EXTRA_CA_CERTS` | Node.js / npm TLS trust           |
| `REQUESTS_CA_BUNDLE`  | Python `requests` / pip TLS trust |
| `SSL_CERT_FILE`       | OpenSSL-based tools               |
| `CURL_CA_BUNDLE`      | curl TLS trust                    |
| `GIT_SSL_CAINFO`      | git TLS trust                     |
| `COMPOSER_CA_FILE`    | PHP Composer TLS trust            |

## Included Dev Container Features

| Feature                                                                                                   | Purpose                            |
| --------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| [`ghcr.io/devcontainers/features/node:lts`](https://github.com/devcontainers/features/tree/main/src/node) | Node.js LTS                        |
| [`ghcr.io/tomgrv/devcontainer-features/githooks`](https://github.com/tomgrv/devcontainer-features)        | Git hooks manager                  |
| [`ghcr.io/tomgrv/devcontainer-features/gitutils`](https://github.com/tomgrv/devcontainer-features)        | Git utilities                      |
| [`ghcr.io/tomgrv/devcontainer-features/gitversion`](https://github.com/tomgrv/devcontainer-features)      | Semantic versioning via GitVersion |

## How the curl wrapper works

The `zscaler-curl` script replaces `/usr/bin/curl` (the real binary is kept at `/usr/bin/curl.real`). When a request is intercepted by a Zscaler gateway and redirected to an authentication/acceptance form, the wrapper:

1. Detects the HTML form response from the gateway.
2. Parses and auto-submits the form fields.
3. Saves the resulting session cookies to `~/.zscaler_cookies.txt`.
4. Re-issues the original request transparently.

All other requests are passed through to `curl.real` unchanged.

## Troubleshooting

**Certificate errors still occurring**
Verify that `gateway.pem` contains the correct root CA (not an intermediate or leaf certificate). You can inspect it with:

```sh
openssl x509 -in .devcontainer/.gateway/certs/gateway.pem -noout -subject -issuer
```

**`update-ca-certificates` has no effect**
Make sure the file extension is `.crt` inside the container (`/usr/local/share/ca-certificates/gateway.crt`). The Dockerfile handles the rename automatically.

**curl wrapper causes issues**
Set `VERBOSE=0` to suppress wrapper log output, or call `/usr/bin/curl.real` directly to bypass the wrapper entirely.

## License

MIT
