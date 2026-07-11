FROM mcr.microsoft.com/devcontainers/base:noble

# Bake the SSL inspection root CA(s) into the image so that HTTPS already
# works during the image build and the devcontainer features installation.
# Tolerates an empty certs folder: the build succeeds even before the
# gateway root CA is dropped in .devcontainer/.gateway/certs/.
COPY ./certs/ /tmp/gateway-certs/
RUN set -e; \
    for pem in /tmp/gateway-certs/*.pem; do \
        [ -f "$pem" ] || continue; \
        cp "$pem" "/usr/local/share/ca-certificates/$(basename "$pem" .pem).crt"; \
    done; \
    update-ca-certificates; \
    rm -rf /tmp/gateway-certs
