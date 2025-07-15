
FROM docker.io/alpine:3.20 AS build

RUN apk add --update --no-cache --no-progress make g++ gcc linux-headers

RUN apk add --update --no-cache --no-progress python3 py3-pip py3-wheel \
   python3-dev git

RUN mkdir /root/wheels

RUN pip wheel -w /root/wheels --no-deps jsonnet

RUN mkdir -p /root/src

COPY trustgraph_configurator/ /root/build/trustgraph_configurator/
COPY scripts/ /root/build/scripts/
COPY setup.py /root/build/setup.py
COPY README.md /root/build/README.md

RUN (cd /root/build && pip wheel -w /root/wheels --no-deps .)

FROM docker.io/alpine:3.20

ENV PIP_BREAK_SYSTEM_PACKAGES=1

COPY --from=build /root/wheels /root/wheels

RUN apk add --update --no-cache --no-progress python3 py3-pip \
      py3-aiohttp

RUN ls /root/wheels

RUN \
    pip install /root/wheels/* && \
    pip cache purge && \
    rm -rf /root/wheels

CMD tg-config-svc
EXPOSE 8080

