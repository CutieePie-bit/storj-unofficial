ARG DOCKER_ARCH

# Fetch ca-certificates file for arch independent builds below
FROM alpine:3.13 as ca-cert
RUN apk -U add ca-certificates

FROM ${DOCKER_ARCH:-amd64}/alpine:3.13

ARG TAG
ARG GOARCH
ENV GOARCH ${GOARCH}
ARG RELVER
ENV RELVER ${RELVER}

EXPOSE 28967/tcp
EXPOSE 28967/udp

WORKDIR /app

COPY --from=ca-cert /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY releases/${RELVER}/${GOARCH:-amd64}/storagenode /app/storagenode
COPY cmd/storagenode/custom /app/custom
COPY cmd/storagenode/entrypoint /entrypoint

RUN chmod +x /entrypoint
COPY cmd/storagenode/dashboard.sh /app/dashboard.sh

RUN chmod +x /app/dashboard.sh
ENTRYPOINT ["/entrypoint"]

# Remove after the alpha
ENV ADDRESS="" \
    EMAIL="" \
    WALLET="" \
    STORAGE="2.0TB" \
    SETUP="false"