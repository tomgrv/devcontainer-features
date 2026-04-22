<!-- @format -->

# PECL Feature

This feature installs PHP extensions from the [PHP Extension Community Library (PECL)](https://pecl.php.net/).

## Quick Start — devcontainer.json

```json
"features": {
    "ghcr.io/tomgrv/devcontainer-features/pecl:5": {
        "extension": "zip"
    }
}
```

## Quick Install — console

```sh
npx tomgrv/devcontainer-features -- pecl
```

## Options

| Options Id | Description                     | Type   | Default Value |
| ---------- | ------------------------------- | ------ | ------------- |
| extension  | The PECL extension to install.  | string | zip           |
