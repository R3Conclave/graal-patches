#!/usr/bin/env bash
set -xeuo pipefail

script_dir=$(dirname ${BASH_SOURCE[0]})
source ${script_dir}/build_common.sh

# Then run the build
runDocker ${container_image_graalvm_build} "./gradlew tarGraal buildGraalSDK --info"
