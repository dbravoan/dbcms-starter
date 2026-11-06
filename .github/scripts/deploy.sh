#!/usr/bin/env bash
# Ejemplo opcional del proyecto consumidor. No se ejecuta en el monorepo.
set -euo pipefail
: "${VPS_HOST:?}" "${VPS_USER:?}" "${VPS_DIR:?}" "${VPS_SSH_KEY:?}" "${VPS_SSH_FINGERPRINT:?}" "${DEPLOY_URL:?}" "${GITHUB_SHA:?}" "${GITHUB_RUN_ID:?}" "${GITHUB_RUN_ATTEMPT:?}"
VPS_PORT=${VPS_PORT:-22}
VPS_PHP_BINARY=${VPS_PHP_BINARY:-php}
VPS_FPM_SERVICE=${VPS_FPM_SERVICE:-}
[[ $VPS_HOST =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ && $VPS_USER =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]
[[ $VPS_PORT =~ ^[0-9]+$ && ${#VPS_PORT} -le 5 && $VPS_PORT -ge 1 && $VPS_PORT -le 65535 ]]
[[ $GITHUB_SHA =~ ^[0-9a-f]{40}$ && $GITHUB_RUN_ID =~ ^[0-9]+$ && $GITHUB_RUN_ATTEMPT =~ ^[0-9]+$ ]]
artifact=$(realpath "${1:?Falta el artefacto}")
test -f "$artifact"
release_name="release-$GITHUB_SHA-$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT"
ssh_dir=$(mktemp -d)
trap 'rm -rf "$ssh_dir"' EXIT
printf '%s\n' "$VPS_SSH_KEY" | tr -d '\r' > "$ssh_dir/key"
chmod 600 "$ssh_dir/key"
ssh-keyscan -T 10 -t ed25519 -p "$VPS_PORT" "$VPS_HOST" > "$ssh_dir/known_hosts" 2>/dev/null
test -s "$ssh_dir/known_hosts"
# Todas las claves devueltas deben coincidir, no solo la primera.
fingerprints=$(ssh-keygen -lf "$ssh_dir/known_hosts" | awk '{print $2}')
test -n "$fingerprints"
while read -r fingerprint; do
  test "$fingerprint" = "$VPS_SSH_FINGERPRINT"
done <<< "$fingerprints"
options=(-i "$ssh_dir/key" -o "UserKnownHostsFile=$ssh_dir/known_hosts" -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes -o ConnectTimeout=15)
remote="$VPS_USER@$VPS_HOST"
upload_dir=$(ssh "${options[@]}" -p "$VPS_PORT" "$remote" 'umask 077; mktemp -d /tmp/dbcms-upload.XXXXXXXXXX')
[[ $upload_dir =~ ^/tmp/dbcms-upload\.[a-zA-Z0-9]+$ ]]
scp "${options[@]}" -P "$VPS_PORT" "$artifact" "$remote:$upload_dir/application.tar.gz"
# Bash recibe argumentos escapados, nunca valores interpolados como código.
printf -v command 'bash -s -- %q %q %q %q %q %q %q' "$VPS_DIR" "$release_name" "$GITHUB_SHA" "$DEPLOY_URL" "$VPS_PHP_BINARY" "$VPS_FPM_SERVICE" "$upload_dir/application.tar.gz"
ssh "${options[@]}" -p "$VPS_PORT" "$remote" "$command" < .github/scripts/deploy-remote.sh
