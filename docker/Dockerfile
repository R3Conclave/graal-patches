FROM ubuntu:20.04

# A build container for Graal project.

LABEL description="R3 GraalVM build container"
LABEL maintainer="conclave@r3.com"
ARG commit_id
LABEL commit_id=${commit_id}

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y \
    git \
    curl \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    gnupg \
    wget  \
    cmake \
    g++ \
    patch \
    python \
    python3 \
    python3-dev \
    vim

# MX and JVMCI versions should be aligned with Graal's build.
# For MX you can take the version of the most recent tag on the day of Graal release
#   from here https://github.com/graalvm/mx/tags/
#   You also need the git revision which you can retrieve as follows:
#   1 - clone the mx repository: git@github.com:graalvm/mx.git
#   2 - find the commit revision with a "git log", for example: "git log tags/5.317.13"
# For JVMCI you can search in the common.json file, for example:
#   https://github.com/oracle/graal/blob/release/graal-vm/22.0/common.json
# We are currently using labsjdk-ce-17 version.

ENV HOME                /home
ENV USER_HOME           ${HOME}
ENV GRADLE_USER_HOME    ${HOME}/.gradle
ENV MX_VERSION          5.317.13
ENV JVMCI_VERSION       22.0-b05
ENV LABSJDK_VERSION     17.0.2
ENV LABSJDK_MAJOR       17
ENV LABSJDK_BUILD       8
ENV LABSJDK_CE_FILE     labsjdk-ce-$LABSJDK_VERSION+$LABSJDK_BUILD-jvmci-$JVMCI_VERSION-linux-amd64.tar.gz
ENV JAVA_HOME           /opt/labsjdk-ce-$LABSJDK_VERSION-jvmci-$JVMCI_VERSION
ENV MX_HOME             /opt/mx-$MX_VERSION

# From MX version 5.294.1 we must use Python 3 otherwise the
# exception 'ImportError: No module named pathlib' is thrown
ENV MX_PYTHON_VERSION   3

# Environment variable to let scripts detect if the docker image is being used
ENV DOCKER_CONTAINER_IS_RUNNING TRUE

# MX
# Download the right MX version and checkout the exact commit to ensure the same code is always used even if the branch is updated
RUN git clone --depth 1 --branch $MX_VERSION  https://github.com/graalvm/mx.git /opt/mx-$MX_VERSION \
  && git -C /opt/mx-$MX_VERSION checkout fac7e8bb \
  && chmod -R a+wx /opt/mx-$MX_VERSION

# labs-openjdk-17
RUN curl -sSL -o /opt/$LABSJDK_CE_FILE https://github.com/graalvm/labs-openjdk-$LABSJDK_MAJOR/releases/download/jvmci-$JVMCI_VERSION/$LABSJDK_CE_FILE \
    && tar -xaf /opt/$LABSJDK_CE_FILE -C /opt \
    && rm -v /opt/$LABSJDK_CE_FILE

# TODO: Investigate if it is possible to safely removed the setup-users.sh script. Be aware that removing the script without making any changes to the existing scripts will generate bugs but the container will still run.
COPY root/scripts/setup-users.sh /scripts/setup-users.sh
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && /scripts/setup-users.sh

# Configure a nicer/more useful prompt that doesn't show the (bogus/artificial) username, but does show git branch.
RUN echo "export PS1=\"conclave \[\e[32m\]\$(git branch | awk '/^\* / { print \$2 }')\[\e[0m\] \w> \"" >>/etc/bash.bashrc

# Make ls use colors.
RUN echo "alias ls='ls --color'" >>/etc/bash.bashrc
