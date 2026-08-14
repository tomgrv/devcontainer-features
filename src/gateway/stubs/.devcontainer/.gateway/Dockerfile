FROM mcr.microsoft.com/devcontainers/base:noble

# Bake the SSL inspection gateway handling into the image so that HTTPS
# already works during the image build itself and the devcontainer features
# installation that follows it — both the root CA trust and the curl form
# interception wrapper are otherwise only installed by the gateway feature's
# own postCreateCommand/install script, which runs too late to help this
# build stage or any earlier-ordered feature.
#
# _install-certs-core.sh / _install-curl-wrapper-core.sh mirror the scripts
# of the same name in the gateway feature itself (src/gateway/) — kept here
# because a Docker build context cannot reach outside .devcontainer/.
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
