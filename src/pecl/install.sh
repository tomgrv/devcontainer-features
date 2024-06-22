#!/bin/sh
set -e

echo "Activating pecl extension '${EXTENSION}'"

# Get php version
phpVersion=$(php -v | head -n 1 | awk '{print $2}')

# Install pecl extension
apt-get update && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get -y install --no-install-recommends lib${EXTENSION}-dev \
	&& pecl install ${EXTENSION} \
	&& mkdir -p /usr/local/php/$phpVersion/ini/conf.d \
	&& echo "extension=${EXTENSION}" >> /usr/local/php/$phpVersion/ini/conf.d/${EXTENSION}.ini \
	&& rm -rf /tmp/pear \
	&& apt-get clean -y && rm -rf /var/lib/apt/lists/*