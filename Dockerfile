FROM alpine:3.22.1 AS builder
RUN apk update && apk add build-base git cmake libffi-dev

COPY txiki.js.patch HEAD_txiki.js /tmp/

WORKDIR /root
RUN mkdir txiki.js && cd txiki.js && \
	git init && \
	git remote add origin https://github.com/saghul/txiki.js.git && \
	git fetch --depth 1 --no-tags origin "$(cat /tmp/HEAD_txiki.js)" && \
	git checkout --detach FETCH_HEAD && \
	git submodule update --init --recursive --depth 1 --jobs "$(nproc)"

WORKDIR /root/txiki.js
RUN git apply /tmp/txiki.js.patch
RUN BUILD_WITH_FFI=OFF make
RUN strip build/tjs


FROM scratch
COPY --from=builder /root/txiki.js/build/tjs /