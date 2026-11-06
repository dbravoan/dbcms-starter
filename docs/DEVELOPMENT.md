# Desarrollar dbCMS

Este recorrido modifica el catálogo del monorepo. Para una web consumidora,
utiliza [Crear proyectos](PROJECTS.md). Las reglas de código pertenecen al
[contrato de arquitectura](../specs/CORE_AND_EXTENSIONS.md). [AGENTS](../AGENTS.md) es solo un índice.

## 1. Preparar el equipo

El monorepo es privado: necesitas acceso autorizado a `dbravoan/dbcms`. Instala Git, Docker Engine y Docker Compose en Linux. No necesitas instalar PHP,
Composer ni Node en el equipo. Reserva puertos libres para Sail. Los siguientes
comandos parten del directorio en el que quieras guardar el repositorio:

```bash
git clone https://github.com/dbravoan/dbcms.git
cd dbcms
mkdir -p bootstrap/cache storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs
test -f .env || cp .env.example .env
docker build -f docker/ci/Dockerfile -t dbcms-dev-tools .
```

La imagen contiene PHP 8.4, Composer y Node 22. Nunca ejecutes PHP, Composer, Artisan o Pest en el equipo anfitrión para el trabajo diario del monorepo: usa Sail. Sin `vendor/`, emplea este bootstrap. En contenedores CI/bootstrap ya existentes ejecuta PHP directamente; no anides Sail. El archivo `.env` se crea solo si
falta. Antes de continuar, revisa sus puertos, credenciales locales y `APP_URL`.
No sustituyas configuraciones, claves ni datos de una instalación existente.

## 2. Instalar el catálogo y arrancar Sail

Desde la raíz del monorepo, instala mediante el manifest del workbench:

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  --volume "$PWD:/var/www/html" --env COMPOSER_AUTH \
  dbcms-dev-tools composer install --working-dir=workbench --prefer-dist --no-interaction
./vendor/bin/sail up -d --build
./vendor/bin/sail npm ci
./vendor/bin/sail npm run build
```

Composer instala todo el catálogo en el `vendor/` raíz y enlaza los paquetes de
`packages/` para desarrollar sin publicarlos. Escribe cambios en `packages/`,
nunca en `vendor/`. El workbench mantiene su propio `composer.lock`. No alternes
su composición con la del starter en una instalación con datos de trabajo.

Sail expone Adminer en `FORWARD_ADMINER_PORT` (8088 por defecto) y configura
el enlace del panel con ese mismo puerto. Fuera de Sail, `CMS_ADMINER_URL` es
opcional; sin ella no se muestra el enlace. Adminer no aparece en el sitio público.

El manifest raíz describe el starter publicado y no contiene rutas locales.
Para comprobarlo, usa un consumidor desechable como indica [Pruebas](TESTING.md).

Solo si acabas de crear un `.env` nuevo y su `APP_KEY` está vacía, genera su
clave una única vez después de instalar vendor:

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  --volume "$PWD:/var/www/html" dbcms-dev-tools php artisan key:generate --no-interaction
```

Conserva esa clave. No ejecutes este paso para sustituir una clave existente ni
sobre una copia de datos cifrados de otra instalación.

## 3. Instalar una web de trabajo

Abre `http://localhost/install` usando el puerto `APP_PORT` configurado. Completa
base de datos, datos reales de empresa y tratamientos, administrador y composición
inicial. La instalación es vacía; el contenido de demostración es una elección
explícita. Configura idiomas y mercados antes de crear contenido.

La descarga de un paquete por Composer no lo instala ni activa en el CMS. Instala
y activa las contribuciones deseadas desde el panel. La composición inicial no
activa módulos opcionales salvo que `CMS_MODULES` los seleccione explícitamente
antes del aprovisionamiento. Si eliges auditoría editorial, declara su tratamiento
`content_audit` y su conservación al configurar los datos de privacidad; sin ellos
el módulo impide guardar contenido auditado. No uses una base de datos
con datos que necesites conservar como fixture de pruebas de instalación.

## 4. Trabajar con las convenciones

```bash
./vendor/bin/sail npm run dev
```

Mantén ese proceso abierto mientras trabajas con assets. En otra terminal puedes
usar `./vendor/bin/sail artisan route:list`. En sesiones posteriores basta con
`./vendor/bin/sail up -d`; `./vendor/bin/sail down` detiene los servicios.

Elige primero el paquete propietario del cambio. Las personalizaciones de una
web pertenecen a `App`; las funciones reutilizables a su paquete. Los controladores
validan, delegan y responden; los servicios de dominio deciden y gestionan
transacciones. Mantén autorización, revisión editorial, publicación, idioma,
mercado y privacidad en HTTP, MCP, trabajos y vistas. Prepara datos fuera de Blade.

Utiliza PHP estricto, Pint y PHPStan nivel 8 sin exclusiones de línea base.
Añade interfaces para sustituciones reales y DTO para datos con significado.
Emite efectos externos después del commit cuando dependan de escrituras atómicas.
Consulta [Extensiones](EXTENSIONS.md) antes de crear módulos, temas o bloques.

Para cambiar dependencias del catálogo, usa Sail y el manifest del workbench;
revisa y guarda su lockfile. Las versiones locales de cada paquete se declaran en
los repositorios `path` del workbench y no son publicaciones reales.

## 5. Comprobar antes de compartir

Ejecuta las comprobaciones del workbench descritas en [Pruebas](TESTING.md).
Las pruebas de instalación, integración y publicación usan archivos **y** bases de
datos desechables. No ejecutes cambios destructivos contra el entorno de Sail.

No hay CI automático en pushes ni PR del monorepo. El autor debe ejecutar las
comprobaciones relevantes, revisar el diff e indicar qué ha probado. La acción de
comprobación manual permite repetirlas; publicar exige verificar el commit exacto.
Guarda evidencia fechada fuera del código público y señala cualquier límite.

## 6. Publicar

Sigue [Publicación](PUBLICATION.md) para actualizar compatibilidades y publicar
solo el paquete cambiado. Un cambio compatible del núcleo no obliga a publicar
otra vez todos sus consumidores. No añadas una versión global al catálogo.

## Documentación

Mantén la documentación en castellano, concisa y con enlaces relativos válidos. Una regla tiene una sola fuente canónica ([AGENTS](../AGENTS.md) es índice; [CONTRIBUTING](https://github.com/dbravoan/dbcms/blob/main/CONTRIBUTING.md) vive en el monorepo).
