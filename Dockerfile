FROM alpine AS build

RUN apk --no-cache add \
        build-base \
        cmake \
        fuse-dev

FROM build AS tmfs
ADD ./tmfs/src /app/src
ADD ./tmfs/CMakeLists.txt /app/

RUN mkdir /build && \
    cd /build && \
    cmake -DCMAKE_BUILD_TYPE=Release /app/ && \
    make -j$(grep -c ^processor /proc/cpuinfo)

FROM build AS sparsebundlefs
ADD ./sparsebundlefs/sparsebundlefs.cpp /app/
ADD ./sparsebundlefs/Makefile /app/

RUN cd /app && \
    make -j$(grep -c ^processor /proc/cpuinfo)

FROM alpine

RUN apk --no-cache add \
    libgcc \
    libstdc++ \
    fuse \
    bash \
    parted

COPY --from=tmfs /build/tmfs /bin
COPY --from=sparsebundlefs /app/sparsebundlefs /bin

RUN mkdir /image /hfs /tm /bind

ADD entry.sh /app/

ENTRYPOINT ["/app/entry.sh"]
