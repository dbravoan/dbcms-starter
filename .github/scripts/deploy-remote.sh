#!/usr/bin/env bash
# Ejecutado por SSH con el usuario propietario del proyecto, nunca como root.
set -euo pipefail
umask 027
app_dir=${1:?}
release_name=${2:?}
sha=${3:?}
base_url=${4:?}
php_binary=${5:-php}
fpm_service=${6:-}
artifact=${7:?}
fail() { printf '%s\n' "$*" >&2; exit 1; }
[[ $app_dir =~ ^/[a-zA-Z0-9_./-]+$ && $app_dir != / && $app_dir != *'/../'* && $app_dir != */.. && $app_dir != *'/./'* ]] || fail 'VPS_DIR debe ser una ruta absoluta sencilla.'
[[ $release_name =~ ^release-[0-9a-f]{40}-[0-9]+-[0-9]+$ && $sha =~ ^[0-9a-f]{40}$ ]] || fail 'Identidad de release inválida.'
[[ $release_name == "release-$sha-"* ]] || fail 'SHA y release no coinciden.'
[[ $base_url =~ ^https://[a-zA-Z0-9][a-zA-Z0-9.:-]*(/[a-zA-Z0-9_/-]*)?$ ]] || fail 'DEPLOY_URL debe ser una URL HTTPS sin parámetros.'
base_url=${base_url%/}
[[ $php_binary =~ ^[a-zA-Z0-9_./-]+$ && $php_binary != -* ]] || fail 'Binario PHP inválido.'
[[ -z $fpm_service || $fpm_service =~ ^[a-zA-Z0-9_.@-]+$ ]] || fail 'Servicio FPM inválido.'
[[ $artifact =~ ^/tmp/dbcms-upload\.[a-zA-Z0-9]+/application.tar.gz$ && -f $artifact && ! -L $artifact ]] || fail 'Artefacto inválido.'
[[ -d $app_dir && ! -L $app_dir && $(realpath "$app_dir") == "$app_dir" ]] || fail 'Prepara un VPS_DIR canónico y propiedad del usuario.'
[[ -f $app_dir/.env && ! -L $app_dir/.env ]] || fail 'Provisiona VPS_DIR/.env antes de desplegar.'
[[ ! -L $app_dir/deployment.lock && ! -L $app_dir/deployment-recovery-required ]] || fail 'Lock inválido.'
exec 9> "$app_dir/deployment.lock"
flock -n 9 || fail 'Otro despliegue tiene el bloqueo.'
[[ ! -e $app_dir/deployment-recovery-required ]] || fail 'Revisa el fallo anterior antes de retirar deployment-recovery-required.'
# Las variables del bloque siguiente pertenecen a PHP, no al shell.
# shellcheck disable=SC2016
"$php_binary" -r '
if (PHP_VERSION_ID < 80400) {fwrite(STDERR, "PHP 8.4 o superior requerido.\n"); exit(1);}
$env = file_get_contents($argv[1]);
function value(string $env, string $key): string {
    preg_match("/^".preg_quote($key, "/")."\\s*=\\s*[\"\x27]?([^\"\x27\\r\\n]*)/m", $env, $m);
    return trim($m[1] ?? "");
}
$key = value($env, "APP_KEY");
$key = str_starts_with($key, "base64:") ? base64_decode(substr($key, 7), true) : $key;
if (!is_string($key) || strlen($key) !== 32 || value($env, "APP_MAINTENANCE_DRIVER") !== "file" || value($env, "APP_ENV") !== "production" || value($env, "APP_DEBUG") !== "false") {
    fwrite(STDERR, "Exige APP_KEY válida, APP_ENV=production, APP_DEBUG=false y APP_MAINTENANCE_DRIVER=file.\n"); exit(1);
}
' "$app_dir/.env"
for path in releases storage uploads; do
  [[ ! -L $app_dir/$path ]] || fail "No se admiten enlaces en $path."
  mkdir -p "$app_dir/$path"
done
[[ ! -e $app_dir/current || -L $app_dir/current ]] || fail 'current debe ser un enlace.'
previous=''
if [[ -L $app_dir/current ]]; then
  previous=$(readlink -f "$app_dir/current")
fi
if [[ -n $previous ]]; then
  [[ $previous == "$app_dir/releases/"* && -f $previous/artisan ]] || fail 'Release actual inválida.'
fi
release_dir="$app_dir/releases/$release_name"
[[ ! -e $release_dir && ! -L $release_dir ]] || fail 'El directorio de release ya existe; reintenta con una ejecución nueva.'
mkdir "$release_dir"
tar -xzf "$artifact" -C "$release_dir"
rm -f "$artifact"
rmdir "$(dirname "$artifact")"
[[ -f $release_dir/artisan && -f $release_dir/vendor/autoload.php && -f $release_dir/public/build/manifest.json ]] || fail 'Artefacto incompleto.'
for path in .env storage public/uploads public/storage bootstrap/cache; do
  [[ ! -L $release_dir/$path ]] || fail "Enlace inesperado en artefacto: $path"
done
mkdir -p "$app_dir/storage/app/public" "$app_dir/storage/framework/cache/data" "$app_dir/storage/framework/sessions" "$app_dir/storage/framework/views" "$app_dir/storage/logs" "$release_dir/bootstrap/cache"
ln -s "$app_dir/.env" "$release_dir/.env"
rm -rf "$release_dir/storage" "$release_dir/public/uploads" "$release_dir/public/storage"
ln -s "$app_dir/storage" "$release_dir/storage"
ln -s "$app_dir/uploads" "$release_dir/public/uploads"
ln -s "$app_dir/storage/app/public" "$release_dir/public/storage"
printf '%s\n' "$sha" > "$release_dir/public/deployment-id.txt"
cd "$release_dir"
"$php_binary" -r 'require "vendor/autoload.php";'
"$php_binary" artisan package:discover --no-interaction
installed=false
[[ ! -f $app_dir/storage/installed ]] || installed=true
if [[ $installed == false ]]; then
  # shellcheck disable=SC2016
  "$php_binary" -r '
$env = file_get_contents($argv[1]);
foreach (["CACHE_STORE" => "file", "SESSION_DRIVER" => "file", "QUEUE_CONNECTION" => "sync"] as $name => $expected) {
    preg_match("/^".$name."\\s*=\\s*[\"\x27]?([^\"\x27\\r\\n]*)/m", $env, $match);
    if (trim($match[1] ?? "") !== $expected) {fwrite(STDERR, "Configura $name=$expected antes de la primera instalación.\n"); exit(1);}
}
' "$app_dir/.env"
fi
[[ ! -e $app_dir/storage/framework/down ]] || fail 'Ya existe mantenimiento ajeno al despliegue.'
maintenance_started=false
activated=false
cookie_jar=$(mktemp)
write_recovery_marker() {
  printf 'release=%s\nsha=%s\nprevious=%s\n' "$release_name" "$sha" "$previous" > "$app_dir/deployment-recovery-required"
}
on_exit() {
  status=$?
  rm -f "$cookie_jar"
  if [[ $status -ne 0 && ( $maintenance_started == true || $activated == true ) ]]; then
    if [[ $maintenance_started == false ]]; then
      "$php_binary" "$release_dir/artisan" down --retry=15 || true
    fi
    write_recovery_marker
    printf '%s\n' 'Fallo: mantenimiento conservado. Revisa la release antes de recuperar.' >&2
  fi
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [[ $installed == true ]]; then
  [[ -n $previous ]] || fail 'Instalación existente sin release actual: requiere revisión manual.'
  maintenance_secret=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
  write_recovery_marker
  maintenance_started=true
  "$php_binary" "$previous/artisan" down --retry=15 --secret="$maintenance_secret"
fi
"$php_binary" artisan config:cache
"$php_binary" artisan route:cache
"$php_binary" artisan view:cache
"$php_binary" artisan event:cache
current_tmp="$app_dir/current.$release_name"
[[ ! -e $current_tmp && ! -L $current_tmp ]] || fail 'Enlace temporal ocupado.'
write_recovery_marker
ln -s "$release_dir" "$current_tmp"
mv -Tf "$current_tmp" "$app_dir/current"
activated=true
"$php_binary" artisan queue:restart
if [[ -n $fpm_service ]]; then
  sudo -n systemctl reload "$fpm_service"
fi
# El secreto de mantenimiento permite comprobar PHP antes de reabrir el tráfico.
health() {
  local status body
  for attempt in 1 2 3 4 5; do
    if [[ $installed == true ]]; then
      curl --silent --show-error --connect-timeout 5 --max-time 15 --cookie-jar "$cookie_jar" --output /dev/null "$base_url/$maintenance_secret" || true
    fi
    body=$(curl --silent --show-error --connect-timeout 5 --max-time 15 --write-out '\n%{http_code}' "$base_url/deployment-id.txt?release=$release_name") || body=''
    status=$(curl --silent --show-error --connect-timeout 5 --max-time 15 --cookie "$cookie_jar" --output /dev/null --write-out '%{http_code}' "$base_url/up") || status=000
    if [[ $body == "$sha"$'\n200' && $status == 200 ]]; then return 0; fi
    printf 'Esperando identidad y salud del release: intento %s/5.\n' "$attempt" >&2
    sleep 2
  done
  return 1
}
health || fail 'La URL pública no confirma identidad y salud del release.'
if [[ $installed == true ]]; then
  "$php_binary" artisan up
  maintenance_started=false
else
  status=$(curl --silent --show-error --connect-timeout 5 --max-time 15 --output /dev/null --write-out '%{http_code}' "$base_url/install")
  [[ $status == 200 ]] || fail 'El instalador no responde HTTP 200.'
fi
# Proteger release activa y anterior; solo borrar directorios con identidad conocida.
retained=1
if [[ -n $previous && $previous != "$release_dir" ]]; then retained=2; fi
while IFS= read -r candidate; do
  [[ $candidate =~ ^release-[0-9a-f]{40}-[0-9]+-[0-9]+$ ]] || continue
  path="$app_dir/releases/$candidate"
  [[ $path != "$release_dir" && $path != "$previous" ]] || continue
  if [[ $retained -lt 4 ]]; then
    retained=$((retained + 1))
  elif [[ ! -L $path ]]; then
    rm -rf -- "$path"
  fi
done < <(find "$app_dir/releases" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' | sort -rn | cut -d ' ' -f2-)
rm -f "$app_dir/deployment-recovery-required"
printf 'Release activa: %s\n' "$release_name"
