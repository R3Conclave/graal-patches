#!/usr/bin/env bash
set -xeuo pipefail

script_dir=$(dirname ${BASH_SOURCE[0]})
source ${script_dir}/build_common.sh

# Publish. All testing should be done before this, i.e. running build.sh
runDocker ${container_image_graalvm_build} "./gradlew publish -i"
