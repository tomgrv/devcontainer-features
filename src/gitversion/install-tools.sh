#!/bin/sh

eval $(
    zz_context "$@"
)


### Install GitVersion
zz_log i "Install Gitversion..."
#dotnet tool install GitVersion.Tool --version ${VERSION:-5.*} --tool-path /usr/local/bin

### Create Docker GitVersion wrapper
zz_log i "Create Docker Gitversion wrapper..."
(
    echo "#!/bin/sh"
    echo "cd \"\$(git rev-parse --show-toplevel)\" && \\"
    echo "docker run --rm -v \"\$(git rev-parse --show-toplevel):/repo\" gittools/gitversion:${VERSION:-6.5.1} /repo \"\$@\""
) > /usr/local/bin/docker-gitversion && chmod ugo+x /usr/local/bin/docker-gitversion


zz_log i "Define Gitversion link..."
ln -sf /usr/local/bin/docker-gitversion /usr/local/bin/gitversion
