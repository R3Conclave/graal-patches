# Graal Patches
This repo maintains changes made to [Oracle's GraalVM](https://github.com/oracle/graal) to get it working with 
[Conclave](https://github.com/R3Conclave/conclave-sdk) and Intel SGX. As such this is not a fork of the GraalVM repo 
but rather just contains the necessary changes as patch files.

## Project structure
The files inside this project are grouped to make the project discovery easy.

### Containers
The folder 'containers' contains the Dockerfile used to generate the docker container image required to build Graal without
having to worry about installing any required tools in your system.

### Patches
The folder 'patches' contains the patch that updates [Oracle's GraalVM](https://github.com/oracle/graal) source code as 
required by [Conclave SDK](https://github.com/R3Conclave/conclave-sdk).

### Scripts
The folder 'scripts' groups all the scripts that are required to build the artifact `graalvm.tar.gz`. However, you must respect the
order they are expected to be run. For instance, you must run the 'build_docker_images.sh' at least once before running 
'build.sh'.

Use the script 'devenv_shell.sh' to start a shell inside a docker container that is properly configured to build Graal manually.

## Building Graal
Before building the artifact keep in mind that this project will clone [Oracle's GraalVM](https://github.com/oracle/graal), 
apply a patch to the cloned repository, and then build the artifact `graalvm.tar.gz`.

Follow the instructions below to build `graalvm.tar.gz` using the scripts:
```
./scripts/build_docker_images.sh
./scripts/build.sh
```

Follow the instructions below to build `graalvm.tar.gz` manually:
```
./scripts/devenv_shell.sh
./gradlew buildGraal
```

## License
The changes made to GraalVM in this repository are open source and distributed under [version 2 of the GNU General Public License with the “Classpath” Exception](LICENSE).