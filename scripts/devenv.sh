#!/usr/bin/env bash
set -euo pipefail
script_dir=$(dirname ${BASH_SOURCE[0]})

source ${script_dir}/build_common.sh

container_name=$(echo "code${code_host_dir}" | sed -e 's/[^a-zA-Z0-9_.-]/_/g')
container_id=$(docker ps -aqf name=^/$container_name\$ || echo "")

if [[ -z ${container_id} ]]; then
  if [ doesContainerImageExist $container_image_graalvm_build ]; then
    docker pull $container_image_graalvm_build
  else
    ${script_dir}/build_publish_docker_images.sh
  fi

  container_id=$(docker run \
       --name=$container_name \
       ${docker_opts[@]+"${docker_opts[@]}"} \
       --privileged \
       --add-host="$(hostname):${docker_ip}" \
       -v /tmp/.X11-unix:/tmp/.X11-unix \
       -d \
       -it \
       $container_image_graalvm_build \
       bash)

  # Set access to docker daemon socket
  if [ "$(uname)" == "Darwin" ]; then
    docker exec -u root $container_id chgrp $(id -g) /var/run/docker.sock
  else
    docker exec -it $@ -u root $container_id bash -c "groupadd -g ${docker_gid} docker_ext || true"
  fi

  # Add entry to container's hostname in /etc/hosts, if it's not there, due to different behaviour in macOS.
  docker exec -u root $container_id sh -c 'grep "\$\(hostname\)" /etc/hosts || printf "%s\t%s\n" $(ip address show docker0 2> /dev/null | sed -n "s/^.*inet \(addr:[ ]*\)*\([^ ]*\).*/\2/p" | cut -d/ -f1) $(hostname) >> /etc/hosts'

  # Let us read/write to the home directory.
  docker exec -u root $container_id chown $(id -u):$(id -g) /home
fi
