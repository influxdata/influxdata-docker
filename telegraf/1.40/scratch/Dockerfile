# Telegraf on scratch: the static (CGO_ENABLED=0) binary plus the minium set of
# runtime files it needs: no shell, package manager, or OS userland. The fetch
# stage provides the GPG-verifies telegraf binary as well as the required OS
# files for a viable Golang environment under /rootfs for the final stage.
# The final scratch stage can then use a single COPY of it avoiding layering.

ARG TELEGRAF_VERSION=1.40.2

FROM telegraf:${TELEGRAF_VERSION}-alpine AS fetch

RUN set -eux; \
    # Copy the required files into a single deployment directory to avoid
    # multiple layers in the target image
    mkdir -p /rootfs/usr/bin /rootfs/etc/telegraf /rootfs/etc/ssl/certs /rootfs/usr/share; \
    cp -a "/usr/bin/telegraf"              /rootfs/usr/bin/telegraf; \
    cp -a "/etc/telegraf/telegraf.conf"    /rootfs/etc/telegraf/telegraf.conf; \
    cp -a "/etc/telegraf/telegraf.d"       /rootfs/etc/telegraf/telegraf.d; \
    cp /etc/ssl/certs/ca-certificates.crt  /rootfs/etc/ssl/certs/ca-certificates.crt; \
    cp -a /usr/share/zoneinfo              /rootfs/usr/share/zoneinfo; \
    # Resolve hostnames via /etc/hosts before DNS
    printf 'hosts: files dns\n' > /rootfs/etc/nsswitch.conf; \
    # Allows pure-Go os/user (CGO_ENABLED=0) to map uid 65532 to a name; without
    # it lookups like procstat's user tag fails silently. USER below sets the
    # identity. We name the account "telegraf" (matching the alpine image) but
    # keep the UID 65532 (according to distroless' "nonroot" UID). 65534 is used
    # for kernel overflows, as unmapped user-namespace ID and as the ID NFS
    # root-squash collapses to, so running as it would make telegraf
    # indistinguishable from a failed-to-map process to security/monitoring
    # tooling; using 65532 avoids this issue.
    # However, "nobody" is kept in the map so 65534-owned files still resolve;
    # we just never run as it.
    printf 'root:x:0:0:root:/root:/sbin/nologin\nnobody:x:65534:65534:nobody:/nonexistent:/sbin/nologin\ntelegraf:x:65532:65532:telegraf:/home/telegraf:/sbin/nologin\n' > /rootfs/etc/passwd; \
    printf 'root:x:0:\nnobody:x:65534:\ntelegraf:x:65532:\n' > /rootfs/etc/group; \
    # /tmp is 1777 (world-writable + sticky) so a container running under an
    # arbitrary uid (e.g. the random uid OpenShift's default SCC assigns) gets a
    # writable /tmp. BuildKit, which official-images publishes with, preserves
    # this mode through COPY; buildah does too.
    # The /home/telegraf should be telegraf owned 65532. We use numeric IDs in
    # chown, not "telegraf", to make sure we the UID/GID are what we have in
    # /etc/passwd and /etc/groups later instead of the UID/GID of the build
    # stage.
    mkdir -p /rootfs/home/telegraf /rootfs/tmp; \
    chown -R 65532:65532 /rootfs/home/telegraf /rootfs/etc/telegraf; \
    chmod 1777 /rootfs/tmp

FROM scratch

# The whole rootfs was staged and GPG-verified in the fetch stage; one COPY
# brings it over. Ownership (including the 65532-owned directories) is preserved
# by docker, podman, and buildah alike.
COPY --from=fetch /rootfs/ /

ENV HOME=/home/telegraf

# Numeric, not a name: with runAsNonRoot=true a kubelet reads the image's USER
# field directly (never its /etc/passwd), so a named user fails admission
# ("cannot verify user is non-root"). 65532 is the distroless "nonroot" uid,
# which we name "telegraf" in the image's /etc/passwd.
# https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/kuberuntime/security_context_others.go#L50
USER 65532:65532

ENTRYPOINT ["/usr/bin/telegraf"]
CMD ["--config", "/etc/telegraf/telegraf.conf", "--config-directory", "/etc/telegraf/telegraf.d"]
