#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nodePackages.node2nix

set -eu -o pipefail

node2nix \
 --development \
 --nodejs-14 \
 --input package.json \
 --output node-packages.nix \
 --composition node-composition.nix
