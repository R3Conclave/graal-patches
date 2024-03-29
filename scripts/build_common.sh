#!/usr/bin/env bash
set -xeuo pipefail
# Sets up common build script parameters and functions

###################################################################
## Configuration
###################################################################

code_host_dir=$PWD

mkdir -p $HOME/.gradle
mkdir -p $HOME/.m2
mkdir -p $HOME/.ccache
mkdir -p $HOME/.mx
mkdir -p $HOME/.container

###################################################################

# Get graal version
graal_version="$(grep -w "graal_version =" ./versions.gradle | cut -d '=' -f 2 | sed "s/[ ']//g")"
if [ -z "$graal_version" ]; then
  echo "Unable to get graal version"
  exit 1
fi

echo "Graal version found: $graal_version"

# Validate Graal version number
if [[ ! ($graal_version =~ ^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$) ]]; then
  echo "Graal version does not follow convention."
  exit 1
fi

###################################################################

# Generate the Docker image tag based on the contents inside the docker directory
# Please be sure that any script that might change the final Docker container image
# is inside the folder docker/scripts. Otherwise, the tag generated won't be
# correct and you run the risk of overwriting existing docker images that are used
# by older release branches. Keep in mind that temporary or build directories should be excluded
# The following code generates the hash based on the contents of a directory and the version of graal used.
# This hash takes into account the contents of each file inside the directory and subdirectories
# The cut command removes the dash at the end.
# All subdirectories with name build and hidden files are excluded. Please be sure that any file
# that is not tracked by git should not be included in this hash.
# In order to allow build_publish_docker_images to detect automatically the new version of graal, the hash generated
# must include the graal_version as well.
pushd ${code_host_dir}
docker_dir_hash=$(find ./docker \( ! -regex '.*/\..*\|.*/root/.*' \) -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -d ' ' -f1)
docker_image_tag=$(echo $docker_dir_hash-$graal_version | sha256sum | cut -d ' ' -f1)
popd

# Docker container images repository
container_image_repo=conclave-docker-dev.software.r3.com/com.r3.conclave

# Docker container images
container_image_graalvm_build=$container_image_repo/graalvm-build:$docker_image_tag

###################################################################

docker_group_add=()
# OS specific settings
if [ "$(uname)" == "Darwin" ]; then
    num_cpus=$( sysctl -n hw.ncpu )
    docker_ip="192.168.65.2"
    network_cmd=("-p" "8000:8000" "-p" "8001:8001")
    host_core_dump_dir="/cores/"
else
    docker_gid=$(cut -d: -f3 < <(getent group docker))
    if [[ "$docker_gid" == "" ]]; then
        echo "You don't appear to have a docker UNIX group configured. This script requires one."
        echo
        echo "Follow the post-install instructions at https://docs.docker.com/install/linux/linux-postinstall/"
        echo "to finish the Docker setup process."
        exit 1
    fi
    docker_group_add=("--group-add" "${docker_gid}")
    num_cpus=$( nproc )
    network_cmd=("--network=host")
    host_core_dump_dir="/var/crash/"

    if [[ $(uname -r) == *microsoft* ]]; then
        docker_ip="172.17.0.2"
    else
        docker_ip=$(ip address show docker0 2> /dev/null | sed -n 's/^.*inet \(addr:[ ]*\)*\([^ ]*\).*/\2/p' | cut -d/ -f1)
        if [ -z "$docker_ip" ]; then
        docker_ip="172.17.0.2"
        fi
    fi
fi

# Part of Graal build process involves cloning and running git commands.
# TeamCity is configured to use mirrors (https://www.jetbrains.com/help/teamcity/git.html#Git-AgentSettings),
# and for the git commands to work properly, the container needs access
# the agent home directory.
agent_home_dir_flags=()
if [ -d "${AGENT_HOME_DIR:-}" ]; then
  agent_home_dir_flags=("-v" "${AGENT_HOME_DIR}/system:/${AGENT_HOME_DIR}/system")
fi

# Beware of the array expansion pattern ${@+"$@"}.
# This is the only safe way to expand an empty array in all bash versions.
# For more information: https://gist.github.com/dimo414/2fb052d230654cc0c25e9e41a9651ebe
docker_opts=(\
    "--rm" \
    "-u" "$(id -u):$(id -g)" \
    "--ulimit" "core=512000000" \
    "--label" "graalvm-build" \
    ${docker_group_add[@]+"${docker_group_add[@]}"} \
    ${network_cmd[@]+"${network_cmd[@]}"} \
    "-v" "$HOME/.gradle:/gradle" \
    "-v" "$HOME/.m2:/home/.m2" \
    "-v" "$HOME/.mx:/home/.mx" \
    "-v" "$HOME/.ccache:/home/.ccache" \
    "-v" "$HOME/.container:/home" \
    "-v" "/var/run/docker.sock:/var/run/docker.sock" \
    "-v" "$host_core_dump_dir:/var/crash/" \
    "-v" "${code_host_dir}:${code_host_dir}" \
    "-e" "GRADLE_USER_HOME=/gradle" \
    "-e" "GRADLE_OPTS=-Dorg.gradle.workers.max=$num_cpus" \
    $(env | cut -f1 -d= | awk 'gsub(/^CONCLAVE_/, "-e CONCLAVE_")') \
    "-w" "$code_host_dir" \
)

function runDocker() {
    image_name=$1
    docker run \
        ${docker_opts[@]+"${docker_opts[@]}"} \
        ${agent_home_dir_flags[@]+"${agent_home_dir_flags[@]}"} \
        ${image_name} \
        bash -c "$2"
}
