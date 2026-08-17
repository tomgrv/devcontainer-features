FROM mcr.microsoft.com/devcontainers/base:noble

# Bake the SSL inspection gateway handling into the image so that HTTPS
# already works during the image build itself and the devcontainer features
# installation that follows it — both the root CA trust and the curl form
# interception wrapper are otherwise only installed by the gateway feature's
# own postCreateCommand/install script, which runs too late to help this
# build stage or any earlier-ordered feature.
#
# _install-certs-core.sh / _install-curl-wrapper-core.sh / _gateway-curl.sh
# are the single source of truth for this mechanics (also used at container
# runtime by configure-certs.sh/install-wrapper.sh, and referenced from the
# same relative path there) — they live here, under the stub tree, because a
# Docker build context cannot reach outside .devcontainer/.
#
# Tolerates an empty certs folder and a missing curl: the build succeeds
# even before the gateway root CA is dropped in .devcontainer/.gateway/certs/.
COPY ./certs/ /tmp/gateway/certs/
COPY ./_install-certs-core.sh ./_install-curl-wrapper-core.sh ./_gateway-curl.sh /tmp/gateway/
RUN chmod +x /tmp/gateway/_gateway-curl.sh \
    && sh /tmp/gateway/_install-certs-core.sh /tmp/gateway/certs \
    && sh /tmp/gateway/_install-curl-wrapper-core.sh install /tmp/gateway/_gateway-curl.sh /usr/local/bin \
    && sh /tmp/gateway/_install-curl-wrapper-core.sh divert /usr/local/bin \
    && rm -rf /tmp/gateway

# Tools that don't consult the OS trust store on their own (npm/pnpm/Node,
# pip, Composer, ...) still need to be told about it explicitly. The feature
# itself sets these as containerEnv, but that only takes effect once the
# container is created — too late for a `RUN npm install` here, or in any
# feature layer that follows this Dockerfile during the image build.
ENV COMPOSER_CA_FILE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt \
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
