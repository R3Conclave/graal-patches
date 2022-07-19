#!/usr/bin/env bash
set -xeuo pipefail

basedir=$(dirname "$(realpath "$0")")
graal_version=$1
graal_commit_id=$2
major_minor_graal_version=$(cut -d '.' -f 1,2 <<< $graal_version)
graal_repo="https://github.com/oracle/graal.git"
graal_branch="release/graal-vm/$major_minor_graal_version"
graal_patch="$basedir/../patches/graal.patch"
graal_dir="graal"

# Clean all directories to avoid issues
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

# Apply the patch to Graal
patch -p1 -i "$graal_patch" --no-backup-if-mismatch

# Change to the previous directory
popd
