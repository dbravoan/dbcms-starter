# Pruebas y comprobaciones

PHP, Composer, Artisan y Pest se ejecutan en contenedores. Sail es el entorno de
trabajo diario; las pruebas que cambian instalación requieren archivos **y** bases
de datos desechables. `RefreshDatabase` no aísla archivos. Conserva la configuración,
claves, datos y bloqueos del entorno de trabajo.

## Composición del proyecto consumidor

Desde una web instalada y con Sail arrancado:

```bash
./vendor/bin/sail up -d
./vendor/bin/sail composer test
./vendor/bin/sail composer check
```

`test` verifica la composición del proyecto y frontend; `check` valida Composer,
Pint, PHPStan, dependencias y compilación. Un consumidor no necesita módulos
opcionales ausentes para ejecutar sus pruebas. Nunca uses los datos de trabajo
para probar instalación o migraciones destructivas.

## Catálogo del monorepo

Desde la raíz del monorepo, con la composición workbench instalada según
[Desarrollo](DEVELOPMENT.md). El catálogo de paquetes se prueba **con la config del
workbench** (`workbench/phpunit.xml` + `workbench/tests/Pest.php`), no con el
`phpunit.xml` / `tests/Pest.php` de la raíz: esos valen solo para la composición
consumidora (`tests/Feature`). Lanzar `sail test workbench/tests/...` sin
`--test-directory` usa la raíz y los tests del workbench fallan (p. ej. sin
`Tests\TestCase` / `seed()`).

### Comandos

```bash
# Suite rápida del workbench (canónico del monorepo)
./vendor/bin/sail composer test:workbench
# Equivalente directo:
./vendor/bin/sail composer --working-dir=workbench test

# Check del workbench (Pint, PHPStan, …)
./vendor/bin/sail composer --working-dir=workbench check

# Un fichero o carpeta Feature del workbench
./vendor/bin/sail pest --test-directory=workbench/tests --configuration=workbench/phpunit.xml \
  workbench/tests/Feature/Admin/ModuleSettingsTest.php
./vendor/bin/sail pest --test-directory=workbench/tests --configuration=workbench/phpunit.xml \
  workbench/tests/Feature/Admin

# Solo la composición raíz (starter / proyecto)
./vendor/bin/sail composer test

# Raíz + workbench
./vendor/bin/sail composer test:all
```

Scripts Composer en la raíz: `test` (raíz), `test:workbench` (delega en
`workbench`), `test:all` (`test` + `test:workbench`). No regeneres `composer.lock`
solo por añadir scripts.

### Usuario del contenedor y discos fake

`./vendor/bin/sail pest`, `sail test` y `sail artisan` ejecutan el proceso como
usuario `sail`. En cambio, `./vendor/bin/sail exec laravel.test …` **sin** `-u`
entra como `root`. Si un test escribe en `storage/framework/testing` (p. ej.
`Storage::fake('local')`) bajo root, quedan directorios `root:root` modo `0700`
y la siguiente corrida como `sail` falla con `Permission denied`.

Para aislar la BD de test u otros env vars, usa siempre `-u sail`:

```bash
./vendor/bin/sail exec -u sail -e DB_DATABASE=testing_<tarea> laravel.test \
  ./vendor/bin/pest --test-directory=workbench/tests --configuration=workbench/phpunit.xml \
  workbench/tests/Feature/ContentAudit
```

No paralelices suites Feature del workbench que compartan la BD `testing`
(p. ej. `Feature/Admin` junto a `Feature/ContentAudit`). Si otro agente está
usando `testing`, crea una BD desechable (`testing_<tarea>`), ejecuta en serie
y bórrala al terminar. Si quedó basura de ownership, corrige solo el árbol de
testing: `./vendor/bin/sail exec laravel.test chown -R sail:sail /var/www/html/storage/framework/testing`
(no apliques `chmod 777` ni toques el resto de `storage/`).

El workbench posee su lockfile y usa el vendor raíz compartido. No reinstales otra
composición para verificar el starter en esa misma instalación; utiliza el entorno
siguiente. Las pruebas usan fixtures mínimos y no cargan demos salvo para probarlas.

## Integración y publicación aisladas

La imagen de calidad copia el código e instala paquetes locales como copias, no
monta la aplicación de trabajo. MySQL usa datos desechables en tmpfs y cada ejecución
crea un contenedor de aplicación nuevo. Desde la raíz:

```bash
docker compose -p dbcms-quality -f docker/ci/compose.yml run --build --rm -T app
docker compose -p dbcms-quality -f docker/ci/compose.yml down --volumes --remove-orphans

QUALITY_SUITE=test:release docker compose -p dbcms-quality -f docker/ci/compose.yml run --build --rm -T app
docker compose -p dbcms-quality -f docker/ci/compose.yml down --volumes --remove-orphans
```

Usa nombres Compose distintos si ejecutas comprobaciones simultáneas. Limpia los
servicios incluso tras fallos. `DBCMS_TEST_ISOLATED=1` describe este entorno: poner
la variable en Sail no lo aísla.

La integración comprueba comportamiento, autorización, publicación, localización
y transacciones. La suite de publicación añade consumidor independiente,
instalación, composición de paquetes y concurrencia real. El consumidor se instala
desde archivos de paquetes con versiones individuales, sin rutas al monorepo.
Se ejecutan también las pruebas raíz para detectar divergencias del starter.

## Automatización elegida

El monorepo no ejecuta CI en `push` ni `pull_request`. Ejecuta las comprobaciones
antes de compartir y comunica sus resultados. La acción manual de comprobación
repite el entorno aislado; la publicación verifica obligatoriamente el commit exacto.
Los proyectos hijos disponen de su propio workflow de comprobación y pueden
activar el despliegue opcional. No confundas esas políticas con el CI del monorepo.

La verificación local del consumidor no demuestra publicación en Packagist. La
comprobación posterior a publicar instala la versión real; sus fallos de propagación
se reintentan sin cambiar tags. Véase [Publicación](PUBLICATION.md).

## Fronteras y evidencias

Simula llamadas externas, no la decisión verificada. Conserva evidencia separada
de permisos, transacciones y carreras reales. Verifica instalación HTTP, APP_KEY
estable, permisos, concurrencia, enlaces de configuración ya provisionados y
rechazo de enlaces inválidos. El ejemplo VPS tiene pruebas desechables de su ciclo;
no sustituyen una prueba del servidor, sus permisos, FPM, workers y scheduler.

Para privacidad en navegador, usa una instalación desechable e intercepta terceros
con respuestas sintéticas. Comprueba que primera visita y rechazo no generan
peticiones opcionales, incluidas imágenes y fondos CSS. Solo se permiten orígenes
necesarios declarados. Aceptar recarga y habilita lo autorizado; retirar lo elimina
y detiene peticiones. Prueba caducidad y cambio de política, sitio solo necesario
sin banner, Tab/Mayús+Tab, Escape, retorno de foco y contraste en ambas marcas.

Guarda resultados fechados, trazas y capturas fuera del árbol público. Informa de
comandos, resultados y límites: una ejecución filtrada no equivale a suite completa,
y una suite local no acredita publicación ni despliegue real.
