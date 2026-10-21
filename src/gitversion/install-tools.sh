#!/bin/sh

eval $(
    zz-context "$@"
)


### Create GitVersion wrapper: Docker image if available, else the dotnet tool
zz-log i "Create Gitversion wrapper..."
cat > /usr/local/bin/docker-gitversion <<EOF
#!/bin/sh
cd "\$(git rev-parse --show-toplevel)" || exit 1
if docker info >/dev/null 2>&1; then
    exec docker run --rm -v "\$PWD:/repo" gittools/gitversion:${VERSION:-6.5.1} /repo "\$@"
fi
PATH="\$PATH:\$HOME/.dotnet/tools"
exec dotnet-gitversion "\$PWD" "\$@"
EOF
chmod ugo+x /usr/local/bin/docker-gitversion


zz-log i "Define Gitversion link..."
ln -sf /usr/local/bin/docker-gitversion /usr/local/bin/gitversion
