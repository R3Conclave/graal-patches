#!/usr/bin/env bash

# This script will clone the specified graal version and commit ID in the current working directory.
# If the repository already exists, it will be removed.

set -xeuo pipefail

# Command line parameters
graal_version=$1
graal_commit_id=$2

basedir=$(dirname "$(realpath "$0")")
major_minor_graal_version=$(cut -d '.' -f 1,2 <<< $graal_version)
graal_repo="https://github.com/oracle/graal.git"
graal_branch="release/graal-vm/$major_minor_graal_version"
graal_dir="graal"

# Delete existing files if present
rm -fr "$graal_dir"

# Download Graal
# Use --filter option to download the minimum amount of data
# Reference: https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/
git clone --filter=tree:0 "$graal_repo" -b "$graal_branch"

# Change to graal directory
pushd $graal_dir

# Change to a specific commit
git checkout "vm-$graal_version"
#Ensure the commit id is the expected one
currentCommitHash=$(git rev-parse --short HEAD)
if [[ "$graal_commit_id" != "$currentCommitHash" ]]; then
    echo "The hash of the commit is not the expected one. Expected: $graal_commit_id, Current: $currentCommitHash"
    exit 1
fi

# Change to the previous directory
popd
