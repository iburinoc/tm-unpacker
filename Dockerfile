FROM ubuntu AS updated
RUN apt-get update

FROM updated AS build

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
        pkg-config \
        build-essential \
        cmake \
        libfuse-dev

FROM build AS tmfs
ADD ./tmfs/src /app/src
ADD ./tmfs/CMakeLists.txt /app/

ARG profile=Release
RUN mkdir /build && \
    cd /build && \
    cmake -DCMAKE_BUILD_TYPE=$profile /app/ && \
    make -j$(grep -c ^processor /proc/cpuinfo)

FROM build AS sparsebundlefs
ADD ./sparsebundlefs/sparsebundlefs.cpp /app/
ADD ./sparsebundlefs/Makefile /app/

RUN cd /app && \
    make -j$(grep -c ^processor /proc/cpuinfo)

FROM updated

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
        fuse \
        parted \
        bindfs

COPY --from=tmfs /build/tmfs /bin
COPY --from=sparsebundlefs /app/sparsebundlefs /bin

RUN mkdir /image /hfs /tm /bind

ADD entry.sh /app/

ENTRYPOINT ["/app/entry.sh"]
