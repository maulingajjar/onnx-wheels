# docker buildx build -t cmake-binaries:3.20.5 -f cmake.Dockerfile .

FROM balenalib/armv7hf-ubuntu:latest-build-20210825 as arm32

RUN [ "cross-build-start" ]

RUN install_packages \
    build-essential \
    wget \
    python3 \
    python3-dev \
    tar \
    libatlas-base-dev

WORKDIR /code
RUN wget https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5.tar.gz && \
    tar zxf cmake-3.20.5.tar.gz

WORKDIR /code/cmake-3.20.5
RUN ./configure --system-curl && \
    make && \
    cd .. && \
    tar -zcvf cmake-armv7hf-3.20.5.tar.gz cmake-3.20.5 && \
    rm -r cmake-3.20.5 && \
    rm -f cmake-3.20.5.tar.gz

RUN [ "cross-build-end" ]

FROM balenalib/aarch64-ubuntu:latest-build-20210825 as arm64

RUN [ "cross-build-start" ]

RUN install_packages \
    build-essential \
    wget \
    python3 \
    python3-dev \
    tar \
    libatlas-base-dev

WORKDIR /code
RUN wget https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5.tar.gz && \
    tar zxf cmake-3.20.5.tar.gz

WORKDIR /code/cmake-3.20.5
RUN ./configure --system-curl && \
    make && \
    cd .. && \
    tar -zcvf cmake-aarch64-3.20.5.tar.gz cmake-3.20.5 && \
    rm -r cmake-3.20.5 && \
    rm -f cmake-3.20.5.tar.gz

RUN [ "cross-build-end" ]

FROM alpine:latest
COPY --from=arm32 /code/cmake-*.tar.gz /home/
COPY --from=arm64 /code/cmake-*.tar.gz /home/
CMD [ "/bin/sh" ]
