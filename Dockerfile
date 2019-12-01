FROM plugins/base:linux-amd64

LABEL maintainer="Ming <642203604@qq.com>" \
  org.label-schema.name="Helm3" \
  org.label-schema.vendor="Ming" \
  org.label-schema.schema-version="1.0"

ENV HELM_VERSION=v3.0.0
ENV PLATFORM=linux-amd64

RUN apk add curl --no-cache \
    && mkdir /tmp/helm_install && cd /tmp/helm_install \
    && curl -L https://get.helm.sh/helm-$HELM_VERSION-$PLATFORM.tar.gz | tar zx \
    && cp */helm /bin/ \
    && rm -rf /tmp/helm_install
ADD drone-helm3.sh /bin/

ENTRYPOINT [ "drone-helm3.sh" ]
