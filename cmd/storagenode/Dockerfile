ARG DOCKER_ARCH

# Fetch ca-certificates file for arch independent builds below
FROM alpine as ca-cert
RUN apk -U add ca-certificates

FROM ${DOCKER_ARCH:-amd64}/alpine
ARG TAG
ARG GOARCH
ENV GOARCH ${GOARCH}
EXPOSE 28967/tcp
EXPOSE 28967/udp
WORKDIR /app
COPY --from=ca-cert /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY release/storagenode_linux_${GOARCH:-amd64} /app/storagenode
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
