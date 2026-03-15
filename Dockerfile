FROM alpine:3.22.1 AS builder
RUN apk update && apk add build-base git cmake libffi-dev

COPY txiki.js.patch HEAD_txiki.js /tmp/

WORKDIR /root
RUN git clone --recursive https://github.com/saghul/txiki.js.git --shallow-submodules --depth 1

WORKDIR /root/txiki.js
RUN git checkout $(cat /tmp/HEAD_txiki.js)
RUN git apply /tmp/txiki.js.patch
RUN make
RUN strip build/tjs


FROM scratch
COPY --from=builder /root/txiki.js/build/tjs /