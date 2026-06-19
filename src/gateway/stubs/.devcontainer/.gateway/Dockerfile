FROM mcr.microsoft.com/devcontainers/base:noble
# Install gateway certificates
RUN apt-get update && apt-get install -y ca-certificates curl jq
COPY --chmod=755 ./certs/gateway.pem /usr/local/share/ca-certificates/gateway.crt
RUN update-ca-certificates

# Export env
ENV NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/gateway.crt
ENV SSL_CERT_FILE=/usr/local/share/ca-certificates/gateway.crt
ENV CURL_CA_BUNDLE=/usr/local/share/ca-certificates/gateway.crt
ENV COMPOSER_CA_FILE=/usr/local/share/ca-certificates/gateway.crt
ENV GIT_SSL_CAINFO=/usr/local/share/ca-certificates/gateway.crt

# Install gateway curl wrapper
COPY --chmod=755 ./gateway-curl.sh /usr/local/bin/gateway-curl
RUN mv /usr/bin/curl /usr/bin/curl.real && \
    ln -s /usr/local/bin/gateway-curl /usr/bin/curl

USER vscode