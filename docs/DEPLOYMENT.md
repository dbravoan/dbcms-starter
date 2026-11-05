# Despliegue VPS opcional de una web

El workflow del starter (`.github/workflows/deploy.yml` en el proyecto hijo) exige la variable de repositorio o entorno `DEPLOY_ENABLED` con valor exacto `true` (`vars.DEPLOY_ENABLED == 'true'`) en los jobs de calidad y despliegue; sin ella no se conecta al servidor ni se construye el artefacto.

El starter incluye un ejemplo adaptable mediante GitHub Actions. Pertenece al
proyecto hijo, está desactivado por defecto y no despliega el monorepo ni los
repositorios de distribución. Puedes sustituirlo por tu procedimiento. No requiere
Ansible ni impone un layout al núcleo. La publicación de paquetes está en
[Publicación](PUBLICATION.md).

## 1. Preparar el servidor

Configura HTTPS, servidor web, PHP 8.4 o superior con las extensiones requeridas
por Composer, base de datos y permisos del usuario de aplicación. El document root
debe apuntar a `<VPS_DIR>/current/public`. Provisiona workers y scheduler según los
módulos usados; el workflow no instala servicios. Fija `retry_after` por encima
del timeout efectivo y consulta el README de Marketing si usas sus colas.

El ejemplo usa esta estructura:

```text
<VPS_DIR>/
├── .env
├── storage/
├── uploads/
├── releases/<identificador>/
└── current -> releases/<identificador>/
```

`.env`, archivos privados, claves Passport, medios y estado de instalación son
persistentes. Provisiona `.env` con `APP_KEY` válida, `APP_ENV=production`,
`APP_DEBUG=false`, `APP_MAINTENANCE_DRIVER=file`, URL HTTPS y configuración real.
Para **una instalación nueva**, genera la clave en tu contenedor de herramientas
local (el que construiste en [Crear proyectos](PROJECTS.md)):

```bash
docker run --rm dbcms-project-tools php -r 'echo "base64:".base64_encode(random_bytes(32)).PHP_EOL;'
```

Copia la salida a `APP_KEY` en un archivo privado preparado desde
`.env.production.example`, completa el resto de valores y transfiérelo por tu
canal seguro a `<VPS_DIR>/.env`. No guardes esa salida en Git ni en logs públicos.
El archivo debe pertenecer al usuario de aplicación y tener permisos `0600`.
El usuario de PHP/CLI y los workers deben poder leerlo. Provisiona antes el
`VPS_DIR` como ruta canónica, sin enlaces, propiedad de ese usuario.

No generes otra clave para una instalación existente: recupera su `.env` y claves
originales. Conserva también
`CMS_INSTALLATION_ID` y claves OAuth. Configura propietario y permisos privados;
no uses `777` ni abras recursivamente archivos privados.

Para la primera instalación utiliza `CACHE_STORE=file`, `SESSION_DRIVER=file` y
`QUEUE_CONNECTION=sync` hasta terminar el instalador. Configura después los
almacenes reales y servicios. Revisa los datos de empresa, tratamientos y retención
antes de abrir la web al público.

## 2. Configurar GitHub

El job utiliza el entorno GitHub `production`; configura sus políticas según tu
proyecto. En el repositorio **del proyecto hijo**, configura estos secrets:

| Secret | Contenido |
| --- | --- |
| `VPS_HOST` | Host del servidor |
| `VPS_USER` | Usuario de aplicación con permisos limitados |
| `VPS_PORT` | Puerto SSH; por defecto 22 |
| `VPS_DIR` | Ruta absoluta de la aplicación |
| `VPS_SSH_KEY` | Clave privada de acceso |
| `VPS_SSH_FINGERPRINT` | Huella SHA256 de la clave de host SSH, verificada por un canal fiable |

Configura estas variables del repositorio:

| Variable | Contenido |
| --- | --- |
| `DEPLOY_ENABLED` | `true` para habilitar el ejemplo |
| `DEPLOY_URL` | URL pública HTTPS, sin barra final |
| `VPS_PHP_BINARY` | Binario PHP del servidor; por defecto `php` |
| `VPS_FPM_SERVICE` | Servicio FPM que se recargará; omitir si lo gestiona el servidor |

Si configuras FPM, autoriza exclusivamente el `sudo -n systemctl reload` de ese
servicio. Verifica previamente la huella por un canal de confianza; escanearla
sin contrastarla no establece confianza. Las credenciales Composer privadas se
configuran mediante `COMPOSER_AUTH` cuando sean necesarias, sin incluirlas en el
artefacto ni mostrarlas en logs.

## 3. Preparar y lanzar

Confirma `composer.lock` y `package-lock.json`, verifica localmente y revisa el diff.
Después sube a `main` o ejecuta manualmente el workflow. Los cambios exclusivamente
documentales quedan excluidos del disparo por push. Sin `DEPLOY_ENABLED=true` no
se conecta al servidor.

La comprobación del mismo commit valida Composer, Pint, PHPStan, pruebas PHP/frontend
y compilación en contenedores PHP 8.4/Node 22. El artefacto instala dependencias de
producción con `composer install` y frontend con `npm ci`, sin actualizar versiones.
Excluye secretos, entornos temporales, datos y herramientas internas.

El envío exige la huella SSH configurada. En el servidor un bloqueo serializa
operaciones, se prepara un release separado y se enlazan recursos persistentes.
Una instalación existente entra en mantenimiento durante la activación. El
workflow no ejecuta migraciones de base de datos. Una primera instalación no
crea usuarios ni datos: deja disponible `/install`.

Se generan cachés, se cambia `current` atómicamente y se reinician los procesos
configurados. La comprobación pública exige HTTP 200 en `/up`, sin aceptar
redirecciones ni errores, e identifica el artefacto recién activado. En una web
nueva también comprueba el instalador. Se conservan cuatro releases contando la activa y la anterior; los datos
persistentes nunca forman parte de esa limpieza. El ejemplo no promete ausencia de interrupciones.

## 4. Completar la primera instalación

Abre `/install`, completa administrador, datos de base de datos y tratamientos
reales. Revisa idiomas/mercados, páginas legales, consentimiento y acceso público.
Configura colas y almacenamiento definitivos y reconstruye cachés con tu cuenta
de aplicación. Pon en marcha los workers apropiados y un único scheduler, o
réplicas coordinadas mediante el mismo almacén de mutex.

## 5. Recuperar un fallo

Antes de entrar en mantenimiento o activar una primera instalación, el proceso
escribe `<VPS_DIR>/deployment-recovery-required`. Solo lo retira cuando termina
correctamente. Los fallos e interrupciones conservan ese marcador y el mantenimiento
que se haya iniciado. Las siguientes ejecuciones se
bloquean hasta que el responsable revise el estado. Conserva logs y el release
fallido; no borres marcadores ni bloqueos para reintentar sin diagnóstico.

Comprueba qué código está activo y qué efectos externos quedaron pendientes. Recupera el conjunto coherente de código, base de
datos y archivos con la copia verificada cuando sea necesario. Cambiar un enlace
no revierte el esquema. No ejecutes `migrate:rollback` ni regeneres claves como
recuperación genérica.

Después de resolver y verificar salud, claves, datos, colas e identidad del
artefacto, retira conscientemente el marcador y el mantenimiento que pertenecen
a esa operación, reinicia los procesos necesarios y vuelve a ejecutar. El workflow
no revierte automáticamente una base de datos modificada.

Las pruebas desechables del ejemplo no acreditan el VPS real. Ensaya primera
instalación, actualización, bloqueo concurrente, fallo de activación, salud inválida
y recuperación antes de utilizarlo con datos reales. Conserva copias y evidencias
fuera de directorios públicos.
