# onnx-wheels
To generate wheels for ONNX and ONNX Runtime which can be installed on ARM architectures, we will use Docker’s buildx functionality which enables building Docker images that work on multiple CPU architectures.

Docker buildx multi-architecture support can make use of either native builder nodes running on different architectures or the QEMU processor emulator. QEMU works by simulating all instructions of a foreign CPU instruction set on the host processor. Linux also has built-in support for running non-native binaries, called binfmt_misc which allows arbitrary executable file formats to be recognized and passed to such emulators.

# QEMU and binfmt-support
As an alternative to installing the QEMU and binfmt-support packages on your host system we will use a docker image to satisfy the corresponding requirements. Satisfy QEMU and binfmt-support requirements by running the following command:
```
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

Verify the entry in binfmt_misc by running the following command:
```
cat /proc/sys/fs/binfmt_misc/qemu-arm
```

The output should look something like this:
```
enabled
interpreter /usr/bin/qemu-arm-static
flags: F
offset 0
magic 7f454c4601010100000000000000000002002800
mask ffffffffffffff00fffffffffffffffffeffffff
```

# Generate CMake binaries
Run the following command to create a Docker image which will contain the CMake binaries that are required for building ONNX and ONNX Runtime wheels:
```
docker buildx build -t cmake-binaries:3.20.5 -f cmake.multistage.Dockerfile .
```

# Generate ONNX and ONNX Runtime wheels
To generate docker images containing ONNX and ONNX Runtime wheels, run the following command after substituting proper values for the parameters:
```
docker buildx build \
       -t onnx-wheels:{ARCH}-{PY_VERSION} \
       -f onnx.Dockerfile \
       --build-arg ARCH={ARCH} \
       --build-arg PY_VERSION={PY_VERSION} \
       --build-arg BUILD={BUILD} .
```

Here are a list of valid values for the parameters:
```
ARCH: armv7hf, aarch64
PY_VERSION: 3.7, 3.8, 3.9
BUILD: arm, arm64
```

For example, the following command generates a docker image which contains ONNX and ONNX Runtime wheels for Python 3.7 on ARMv7:
```
docker buildx build \
       -t onnx-wheels:armv7hf-3.7 \
       -f onnx.Dockerfile \
       --build-arg ARCH=armv7hf \
       --build-arg PY_VERSION=3.7 \
       --build-arg BUILD=arm .
```

And the following command generates a docker image which contains ONNX and ONNX Runtime wheels for Python 3.8 on AArch64:
```
docker buildx build \
       -t onnx-wheels:aarch64-3.8 \
       -f onnx.Dockerfile \
       --build-arg ARCH=aarch64 \
       --build-arg PY_VERSION=3.8 \
       --build-arg BUILD=arm64 .
```

The wheels are located under the `/home` folder of the docker image built in the above step. The wheels can be copied to the host machine by running the appropriate container and using the [`docker cp`](https://docs.docker.com/engine/reference/commandline/cp/) command.

For example, ONNX and ONNX Runtime wheels for Python 3.7 on ARMv7 will appear as follows:
```
onnx-1.11.0-cp37-cp37m-linux_armv7l.whl
onnxruntime-1.11.0-cp37-cp37m-linux_armv7l.whl
```

And ONNX and ONNX Runtime wheels for Python 3.8 on AArch64 will appear as follows:
```
onnx-1.11.0-cp38-cp38m-linux_aarch64.whl
onnxruntime-1.11.0-cp38-cp38m-linux_aarch64.whl
```
# Test wheels
To test the wheels on ARM32 architecture, launch a Docker instance using the following command and install the desired wheels:
```
docker run --platform linux/arm -it --rm balenalib/raspberrypi3-python:3.7-build /bin/bash
```

To test the wheels on ARM64 architecture, launch a Docker instance using the either one of following commands and install the desired wheels:
```
docker run --platform linux/arm64 -it --rm balenalib/raspberrypi4-64-python:3.7-build /bin/bash
docker run --platform linux/arm64 -it --rm balenalib/aarch64-ubuntu-python:3.7-focal-build /bin/bash
```