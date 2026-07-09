# Telegraf on scratch: the static (CGO_ENABLED=0) binary plus only the runtime
# files it needs — no shell, package manager, or OS userland. The alpine stage
# GPG-verifies the release and assembles the exact final image tree under
# /rootfs; the scratch stage is a single COPY of it.

ARG TELEGRAF_VERSION=1.39.1

FROM alpine:3.23 AS fetch
ARG TELEGRAF_VERSION

RUN set -eux; \
    case "$(apk --print-arch)" in \
        x86_64)  ARCH='amd64';; \
        aarch64) ARCH='arm64';; \
        *) echo "Unsupported architecture: $(apk --print-arch)" >&2; exit 1;; \
    esac; \
    apk add --no-cache ca-certificates tzdata wget gnupg tar; \
    update-ca-certificates; \
    mkdir -p ~/.gnupg; echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf; \
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 24C975CBA61A024EE1B631787C3D57159FC2F927; \
    base="telegraf-${TELEGRAF_VERSION}_linux_${ARCH}.tar.gz"; \
    wget --no-verbose "https://dl.influxdata.com/telegraf/releases/${base}"; \
    wget --no-verbose "https://dl.influxdata.com/telegraf/releases/${base}.asc"; \
    gpg --batch --verify "${base}.asc" "${base}"; \
    mkdir -p /src /rootfs/usr/bin /rootfs/etc/telegraf /rootfs/etc/ssl/certs /rootfs/usr/share; \
    tar -C /src -xzf "${base}"; \
    # Copy from the explicit `telegraf-<v>/` prefix: release tar roots vary (some
    # add a leading ./), which makes a fixed --strip-components unreliable.
    src="/src/telegraf-${TELEGRAF_VERSION}"; \
    cp -a "${src}/usr/bin/telegraf"           /rootfs/usr/bin/telegraf; \
    cp -a "${src}/etc/telegraf/telegraf.conf" /rootfs/etc/telegraf/telegraf.conf; \
    cp -a "${src}/etc/telegraf/telegraf.d"    /rootfs/etc/telegraf/telegraf.d; \
    cp /etc/ssl/certs/ca-certificates.crt     /rootfs/etc/ssl/certs/ca-certificates.crt; \
    cp -a /usr/share/zoneinfo                 /rootfs/usr/share/zoneinfo; \
    # Resolve hostnames via /etc/hosts before DNS.
    printf 'hosts: files dns\n' > /rootfs/etc/nsswitch.conf; \
    # Lets pure-Go os/user (CGO_ENABLED=0) map uid 65532 to a name; without it
    # lookups like procstat's user tag fail silently. USER below sets the identity.
    # We run as 65532 (the distroless "nonroot" uid), NOT 65534/nobody: 65534 is the
    # kernel overflow uid — the id that unmapped user-namespace ids and NFS root-squash
    # collapse to — so running as it would make telegraf indistinguishable from a
    # failed-to-map process to security/monitoring tooling. 65532 sits outside that.
    #   overflow uid default 65534: https://www.kernel.org/doc/html/latest/admin-guide/sysctl/kernel.html
    #   unmapped userns id -> overflow: https://man7.org/linux/man-pages/man7/user_namespaces.7.html
    #   distroless nonroot = 65532:     https://github.com/GoogleContainerTools/distroless/blob/main/common/variables.bzl
    # (nobody is kept in the map so 65534-owned files still resolve; we just never run as it.)
    printf 'root:x:0:0:root:/root:/sbin/nologin\nnobody:x:65534:65534:nobody:/nonexistent:/sbin/nologin\nnonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin\n' > /rootfs/etc/passwd; \
    printf 'root:x:0:\nnobody:x:65534:\nnonroot:x:65532:\n' > /rootfs/etc/group; \
    # $HOME and a writable /tmp for 65532. We set ownership, not mode bits like
    # 1777: buildah's COPY preserves a dir's ownership but not its mode. Numeric id,
    # not "nonroot": this chown runs in the alpine stage, whose /etc/passwd has no
    # nonroot user, so a BusyBox name lookup would fail ("unknown user/group") and
    # abort under set -eux. A numeric id skips the passwd lookup entirely.
    #   busybox chown name lookup + err string (xget_uidgid; mirror linked from busybox.net/source.html):
    #   https://github.com/vda-linux/busybox_mirror/blob/ec0c5cc142f1f9ea57235df5d093fbe180ad9c7d/libpwdgrp/uidgid_get.c#L77-L80
    mkdir -p /rootfs/home/nonroot /rootfs/tmp; chown 65532:65532 /rootfs/home/nonroot /rootfs/tmp

FROM scratch

ARG TELEGRAF_VERSION
ENV TELEGRAF_VERSION=${TELEGRAF_VERSION}
LABEL org.opencontainers.image.title="telegraf" \
      org.opencontainers.image.description="Distroless Telegraf — static binary on scratch (no shell, no OS userland, non-root)" \
      org.opencontainers.image.version="${TELEGRAF_VERSION}" \
      org.opencontainers.image.source="https://github.com/influxdata/influxdata-docker" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.vendor="InfluxData Inc." \
      org.opencontainers.image.licenses="MIT"

# The whole rootfs was staged and GPG-verified in the fetch stage; one COPY
# brings it over. Ownership (incl. the 65532-owned /home/nonroot and /tmp) is
# preserved by docker, podman, and buildah alike.
COPY --from=fetch /rootfs/ /

ENV HOME=/home/nonroot

# Numeric, not a name: with runAsNonRoot=true the kubelet reads the image's USER
# field directly (never its /etc/passwd), so a named user fails admission
# ("cannot verify user is non-root"). 65532 is the distroless "nonroot" uid.
# https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/kuberuntime/security_context_others.go#L50
USER 65532:65532

ENTRYPOINT ["/usr/bin/telegraf"]
CMD ["--config", "/etc/telegraf/telegraf.conf", "--config-directory", "/etc/telegraf/telegraf.d"]
