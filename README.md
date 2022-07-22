# Graal Patches
This repo maintains changes made to [GraalVM](https://github.com/oracle/graal) to get it working with 
[Conclave](https://github.com/R3Conclave/conclave-sdk) and Intel SGX. As such this is not a fork of the GraalVM repo 
but rather just contains the necessary changes as patch files.

## Project structure
The files inside this project are grouped to make the project discovery easy.

| Directory                              | Description                                                                                                                                                   |
|----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`docker/`](docker)                    | Contains the Dockerfile used to generate the Docker image required to build Graal without having to worry about installing any required tools in your system. |
| [`graal-sdk/`](graal-sdk)              | Contains the build.gradle file used to generate the artifact graal-sdk.jar |
| [`graalvm/`](graalvm)                  | Container the build.gradle file used to generate the artifact graalvm.tar.gz |
| [`patches/`](patches)                  | Contains the modifications to [GraalVM](https://github.com/oracle/graal) as patch files.                                                                      |
| [`scripts/`](scripts)                  | Contains all the scripts that are required to build the artifact `graalvm.tar.gz`.                                                                            |

## Building Graal
Before building the artifact keep in mind that this project will clone [GraalVM](https://github.com/oracle/graal), 
apply a patch to the cloned repository, and then build the artifact `graalvm.tar.gz`.

Follow the instructions below to build `graalvm.tar.gz` using the scripts:
```
./scripts/build_docker_images.sh
./scripts/build.sh
```

You can also start a shell inside the Docker container to build Graal manually:
```
./scripts/devenv_shell.sh
./gradlew publishMavenPublicationToLocalRepoRepository
```

The artifact can be found in the directory `build/distributions`.

## License
The changes made to GraalVM in this repository are open source and distributed under [version 2 of the GNU General 
Public License with the “Classpath” Exception](LICENSE).
