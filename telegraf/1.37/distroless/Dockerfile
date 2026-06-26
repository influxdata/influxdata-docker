# syntax=docker/dockerfile:1
#
# Telegraf, distroless variant — the static telegraf binary on
# gcr.io/distroless/static-debian13: no shell, no package manager, runs non-root.
#
# This variant has no shell and no entrypoint.sh (so no setcap/setpriv): that
# rules out the ICMP ping input, privileged (<1024) ports, and shell-out plugins
# (exec, snmp, sensors). It targets network-listener / push workloads (e.g.
# http_listener_v2, statsd, prometheus, influxdb_v2 over HTTPS) that need none of those.

############################
# Stage 1 — fetch + verify #
############################
# Throwaway builder (curl/gnupg/tar to fetch + verify the release); never shipped.
# Pinned tag@digest: digest locks the build, tag tracks sibling telegraf/1.37/alpine.
# https://hub.docker.com/_/alpine
FROM alpine:3.22@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce AS fetch

ENV TELEGRAF_VERSION=1.37.3

# Per-arch SHA256 of the release tarball: a reproducibility / change-detection
# pin (the GPG check below is the trust anchor). Verify against the published
# .DIGESTS:
#   curl -fsSL https://dl.influxdata.com/telegraf/releases/telegraf-1.37.3_linux_amd64.tar.gz.DIGESTS  # and _arm64
ARG TELEGRAF_SHA256_AMD64=7d7297fae9d2146c811b9a6170ccc6c4e2149e08e1ef1e39bbc523b5a0d075ae
ARG TELEGRAF_SHA256_ARM64=909851f875555936bb5fc6c3dc4794bab5a9b23b24a4bef1188b218b57b56850

# BuildKit sets TARGETARCH (amd64|arm64); read as ${TARGETARCH:-} below so set -u
# is fine when it's unset, with a uname -m fallback for engines that don't set it
# (e.g. Kaniko).
ARG TARGETARCH=""

RUN apk add --no-cache curl gnupg tar

WORKDIR /work
RUN set -eux; \
    # Target arch: BuildKit's TARGETARCH, else map uname -m (see ARG above).
    target_arch="${TARGETARCH:-}"; \
    if [ -z "${target_arch}" ]; then \
        case "$(uname -m)" in \
            x86_64)  target_arch="amd64" ;; \
            aarch64) target_arch="arm64" ;; \
            *) echo "cannot map uname -m '$(uname -m)' to a telegraf arch" >&2; exit 1 ;; \
        esac; \
    fi; \
    case "${target_arch}" in \
        amd64) arch="amd64"; sha256="${TELEGRAF_SHA256_AMD64}" ;; \
        arm64) arch="arm64"; sha256="${TELEGRAF_SHA256_ARM64}" ;; \
        *) echo "unsupported target arch: ${target_arch}" >&2; exit 1 ;; \
    esac; \
    tarball="telegraf-${TELEGRAF_VERSION}_linux_${arch}.tar.gz"; \
    base="https://dl.influxdata.com/telegraf/releases"; \
    curl -fsSL -o telegraf.tar.gz     "${base}/${tarball}"; \
    curl -fsSL -o telegraf.tar.gz.asc "${base}/${tarball}.asc"; \
    \
    echo "==> verifying SHA256"; \
    echo "${sha256}  telegraf.tar.gz" | sha256sum -c -; \
    \
    echo "==> verifying GPG signature"; \
    export GNUPGHOME="$(mktemp -d)"; \
    echo "disable-ipv6" > "${GNUPGHOME}/dirmngr.conf"; \
    # InfluxData signing key (same fingerprint the default/alpine images use),
    # fetched from the keyserver at build time.
    gpg --batch --keyserver hkp://keyserver.ubuntu.com \
        --recv-keys 24C975CBA61A024EE1B631787C3D57159FC2F927; \
    gpg --batch --verify telegraf.tar.gz.asc telegraf.tar.gz; \
    gpgconf --kill all || true; \
    \
    echo "==> extracting binary + default config"; \
    tar -xzf telegraf.tar.gz; \
    install -D -m 0755 \
        "telegraf-${TELEGRAF_VERSION}/usr/bin/telegraf" /out/usr/bin/telegraf; \
    install -D -m 0644 \
        "telegraf-${TELEGRAF_VERSION}/etc/telegraf/telegraf.conf" \
        /out/etc/telegraf/telegraf.conf; \
    # Empty drop-in dir, matching the default images' /etc/telegraf/telegraf.d.
    install -d -m 0755 /out/etc/telegraf/telegraf.d; \
    \
    echo "==> sanity check (static binary runs)"; \
    /out/usr/bin/telegraf --version

############################
# Stage 2 — distroless     #
############################
# Final base. distroless/static ships exactly what a CGO_ENABLED=0 Go binary
# needs — CA bundle (HTTPS outputs like influxdb_v2), nsswitch.conf, tzdata, and
# non-root 65532 in /etc/passwd — with no libc, shell, or package manager.
# static-debian13 is the current default track (no per-version tag, hence :latest).
# https://github.com/GoogleContainerTools/distroless
# Pinned tag@digest: digest locks the build, tag documents the track.
FROM gcr.io/distroless/static-debian13:latest@sha256:3592aa8171c77482f62bbc4164e6a2d141c6122554ace66e5cc910cadb961ff0

ARG TELEGRAF_VERSION=1.37.3
LABEL org.opencontainers.image.title="telegraf" \
      org.opencontainers.image.description="Distroless Telegraf — static binary on gcr.io/distroless/static-debian13 (no shell, non-root)" \
      org.opencontainers.image.version="${TELEGRAF_VERSION}" \
      org.opencontainers.image.source="https://github.com/influxdata/influxdata-docker" \
      org.opencontainers.image.base.name="gcr.io/distroless/static-debian13" \
      org.opencontainers.image.vendor="InfluxData Inc." \
      org.opencontainers.image.licenses="MIT"

# Verified binary + default config + empty drop-in dir; users mount their own over these.
COPY --from=fetch /out/usr/bin/telegraf /usr/bin/telegraf
COPY --from=fetch /out/etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf
COPY --from=fetch /out/etc/telegraf/telegraf.d /etc/telegraf/telegraf.d

# Same ports as the default images; all >= 1024, so no privileged-port cap needed.
EXPOSE 8125/udp 8092/udp 8094

# Numeric UID so runAsNonRoot / read-only-rootfs validation works; base defines 65532.
USER 65532:65532

# Exec form (distroless has no /bin/sh for a shell-form entrypoint); also replaces
# the default image's entrypoint.sh (setcap/setpriv), unneeded for this non-root workload.
ENTRYPOINT ["/usr/bin/telegraf"]
CMD ["--config", "/etc/telegraf/telegraf.conf", "--config-directory", "/etc/telegraf/telegraf.d"]
