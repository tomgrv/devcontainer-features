#!/bin/sh
set -e

#### Bootstrap the Laravel project (deps, env, app key, forwarding, sail, seed)
#### Shared with the `init` command so both stay in sync.
init
