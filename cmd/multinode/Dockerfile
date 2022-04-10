ARG DOCKER_ARCH

# Fetch ca-certificates file for arch independent builds below
FROM alpine:3.13 as ca-cert
RUN apk -U add ca-certificates

# Fetch Alpine container
FROM ${DOCKER_ARCH:-amd64}/alpine:3.13

ARG GOARCH
ARG RELVER
ARG TAG

ENV GOARCH ${GOARCH}
ENV RELVER ${RELVER}

EXPOSE 15002

WORKDIR /app
COPY --from=ca-cert /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY releases/${RELVER}/${GOARCH:-amd64}/multinode /app/multinode
COPY cmd/multinode/entrypoint /entrypoint
RUN chmod +x /entrypoint
ENTRYPOINT ["/entrypoint"]