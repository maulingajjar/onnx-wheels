# docker buildx build -t onnx-wheels:armv7hf-3.7 -f onnx.Dockerfile --build-arg ARCH=armv7hf --build-arg PY_VERSION=3.7 --build-arg BUILD=arm .
# docker buildx build -t onnx-wheels:armv7hf-3.8 -f onnx.Dockerfile --build-arg ARCH=armv7hf --build-arg PY_VERSION=3.8 --build-arg BUILD=arm .
# docker buildx build -t onnx-wheels:armv7hf-3.9 -f onnx.Dockerfile --build-arg ARCH=armv7hf --build-arg PY_VERSION=3.9 --build-arg BUILD=arm .
# docker buildx build -t onnx-wheels:aarch64-3.7 -f onnx.Dockerfile --build-arg ARCH=aarch64 --build-arg PY_VERSION=3.7 --build-arg BUILD=arm64 .
# docker buildx build -t onnx-wheels:aarch64-3.8 -f onnx.Dockerfile --build-arg ARCH=aarch64 --build-arg PY_VERSION=3.8 --build-arg BUILD=arm64 .
# docker buildx build -t onnx-wheels:aarch64-3.9 -f onnx.Dockerfile --build-arg ARCH=aarch64 --build-arg PY_VERSION=3.9 --build-arg BUILD=arm64 .

ARG ARCH
ARG PY_VERSION
FROM balenalib/${ARCH}-ubuntu-python:${PY_VERSION}-focal-build-20220622 as base
ARG PY_VERSION
ARG ARCH
ARG BUILD

RUN [ "cross-build-start" ]

RUN install_packages \
    sudo \
    build-essential \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    python3-dev \
    git \
    tar \
    libatlas-base-dev \
    aria2

RUN pip3 install --upgrade pip
RUN pip3 install --upgrade setuptools
RUN pip3 install --upgrade wheel
RUN pip3 install numpy==1.21.5

RUN pip3 install pybind11
ENV CMAKE_PREFIX_PATH "$CMAKE_PREFIX_PATH:/usr/local/lib/python$PY_VERSION/site-packages/pybind11/share/cmake/pybind11"

# CMAKE
WORKDIR /code
COPY --from=cmake-binaries:3.20.5 /home/cmake-${ARCH}-3.20.5.tar.gz /code/
RUN tar zxf cmake-${ARCH}-3.20.5.tar.gz
WORKDIR /code/cmake-3.20.5
RUN sudo make install

# BUILD PROTOBUF
WORKDIR /code
RUN git clone --single-branch --branch v3.19.0 --recursive https://github.com/protocolbuffers/protobuf protobuf
WORKDIR /code/protobuf
RUN cmake cmake -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release
RUN make -j`nproc` && \
    make install

# START BUILDING WHEELS
RUN mkdir -p /wheels

# ONNX WHEEL
WORKDIR /code
RUN git clone --single-branch --branch v1.11.0 https://github.com/onnx/onnx
WORKDIR /code/onnx
RUN python3 setup.py bdist_wheel && \
    pip3 install --force-reinstall dist/* && \
    cp dist/* /wheels/

# ONNXRUNTIME WHEEL
WORKDIR /code
RUN git clone --single-branch --branch v1.11.0 --recursive https://github.com/microsoft/onnxruntime onnxruntime
WORKDIR /code/onnxruntime
RUN ./build.sh --skip_tests --use_openmp --config MinSizeRel --${BUILD} --build_wheel --update --build --build_shared_lib --parallel && \
    cp build/Linux/MinSizeRel/dist/*.whl /wheels/

RUN [ "cross-build-end" ]

FROM alpine:latest
COPY --from=base /wheels/* /home/
CMD [ "/bin/sh" ]
