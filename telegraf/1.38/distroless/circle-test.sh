# Smoke tests for the telegraf distroless variant.
#
# This file is *sourced* by the repository-root circle-test.sh (see the
# "Iterate over every circle-test.sh script" loop). It therefore relies on the
# helpers and variables defined there:
#   - assert_equals / assert_contains  (append to failed_tests on mismatch)
#   - failed_tests                     (array; the root script reports + exits)
#   - tags                             (the images successfully built this run)
#
# The image is built by the root script as tag "telegraf:1.38-distroless"
# (path telegraf/1.38/distroless -> first '/' becomes ':', the rest become '-').

tag="telegraf:1.38-distroless"

log_msg "Testing ${tag}"

# 1. The binary runs and reports the version we built.
version_output="$(docker run --rm "${tag}" --version 2>&1 || true)"
assert_contains "${version_output}" "Telegraf" "${tag} --version prints Telegraf"
assert_contains "${version_output}" "1.38.4"   "${tag} --version reports 1.38.4"

# 2. The image runs as the non-root distroless user (uid 65532), not root.
#    `id` is not available (no shell/coreutils), so read the configured user
#    from the image metadata instead.
image_user="$(docker inspect --format '{{.Config.User}}' "${tag}" 2>&1 || true)"
assert_equals "${image_user}" "65532:65532" "${tag} runs as non-root 65532"

# 3. It is genuinely shell-less: overriding the entrypoint with a shell MUST
#    fail (there is no /bin/sh in distroless). A success here would mean the
#    hardening regressed.
if docker run --rm --entrypoint /bin/sh "${tag}" -c "true" >/dev/null 2>&1; then
  failed_tests+=("${tag} unexpectedly has a working /bin/sh (should be shell-less)")
fi

# 4. The default config telegraf ships is present and parses. `--test`
#    instantiates the plugins enabled in the supplied config (the default config
#    enables only the host inputs cpu/disk/mem/... and no outputs), runs one
#    collection cycle to stdout, then exits non-zero on a bad config. This
#    confirms the static binary runs on the distroless base and that the config +
#    tzdata + /etc/passwd it needs are in place. It is hermetic (the default
#    inputs need no network) but does NOT exercise the CA bundle: with no
#    [[outputs.*]] enabled there is no outbound TLS, so this is not a CA-cert
#    check. Capture the exit code (not just stdout) so a parse/load failure that
#    still happens to print "cpu" can't pass; the `if`/`else $?` keeps a non-zero
#    exit from aborting the root script that sources this file under `set -e`.
if config_test="$(docker run --rm "${tag}" \
  --config /etc/telegraf/telegraf.conf --test 2>&1)"; then
  config_rc=0
else
  config_rc=$?
fi
assert_equals "${config_rc}" "0" "${tag} --test exits 0 on the default config"
assert_contains "${config_test}" "cpu" "${tag} default config loads the cpu input"
