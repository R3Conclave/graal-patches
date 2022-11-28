#!/usr/bin/env bash

# This script runs clears any unstaged changes from the local graal repo and then applies Conclave patches.

set -xeuo pipefail

basedir=$(dirname "$(realpath "$0")")
graal_patch="$basedir/../patches/graal.patch"
graal_dir="graal"

# Change to graal directory
pushd $graal_dir

# Discard unstaged changes
git checkout .

# Apply the patch to Graal
patch -p1 -i "$graal_patch" --no-backup-if-mismatch

# Change to the previous directory
popd
