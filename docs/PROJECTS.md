# Crear y mantener una web

Este recorrido consume paquetes publicados; no desarrolla el monorepo. El núcleo
y cada módulo o tema tienen ciclos de versiones independientes. Composer resuelve las
restricciones y el `composer.lock` del proyecto fija la combinación instalada.
Los comandos de creación requieren que el starter y sus dependencias ya estén
publicados. La existencia de este repositorio no garantiza su disponibilidad.

## 1. Preparar Git y Docker

Necesitas Git, Docker Engine y Docker Compose. No ejecutes PHP, Composer, Artisan
ni Pest en el equipo anfitrión. Puedes empezar por la plantilla GitHub o por
Composer. Ambas opciones producen la misma aplicación consumidora.

### Opción A: plantilla de GitHub

En [dbravoan/dbcms-starter](https://github.com/dbravoan/dbcms-starter), selecciona **Use this template**, crea tu repositorio
y clónalo. Desde su raíz:

```bash
git clone https://github.com/TU_CUENTA/mi-web.git
cd mi-web
mkdir -p bootstrap/cache storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs
test -f .env || cp .env.example .env
docker build -f docker/ci/Dockerfile -t dbcms-project-tools .
docker run --rm --user "$(id -u):$(id -g)" \
  --volume "$PWD:/var/www/html" --env COMPOSER_AUTH \
  dbcms-project-tools composer install --prefer-dist --no-interaction
```

Composer genera el lockfile de tu proyecto. La plantilla no contiene `packages/`
ni workbench. No necesitas crear una entrada Packagist para tu web.

### Opción B: crear con Composer

Para disponer del mismo entorno PHP 8.4 desde una máquina sin PHP, clona primero
la distribución del starter en un directorio de herramientas y construye su imagen.
Desde el directorio padre de tu futura web:

```bash
git clone https://github.com/dbravoan/dbcms-starter.git dbcms-tools
docker build -f dbcms-tools/docker/ci/Dockerfile -t dbcms-project-tools dbcms-tools
docker run --rm --user "$(id -u):$(id -g)" \
  --volume "$PWD:/workspace" --workdir /workspace --env COMPOSER_AUTH \
  dbcms-project-tools composer create-project --prefer-dist --no-interaction \
  'dbravoan/dbcms-starter:^1.0' mi-web
cd mi-web
mkdir -p bootstrap/cache storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs
test -f .env || cp .env.example .env
git init
git add .
git commit -m "Crear proyecto dbCMS"
```

El clonado de herramientas solo sirve para construir la imagen, no forma parte
de tu web. Configura el remoto del repositorio propio y sube el proyecto cuando
hayas revisado sus archivos. Conserva `composer.lock` y `package-lock.json`.

Solo si acabas de crear un `.env` nuevo y su `APP_KEY` está vacía, genera su
clave una única vez después de instalar vendor:

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  --volume "$PWD:/var/www/html" dbcms-project-tools php artisan key:generate --no-interaction
```

Conserva esa clave. No ejecutes este paso para sustituir una clave existente ni
sobre una copia de datos cifrados de otra instalación.

## 2. Configurar y arrancar

Desde la raíz de la nueva web, revisa `.env`: puertos Sail disponibles, base de
datos local, `APP_URL` y correo de pruebas. No publiques ese archivo ni claves.

```bash
./vendor/bin/sail up -d --build
./vendor/bin/sail npm ci
./vendor/bin/sail npm run build
```

Abre `http://localhost/install` con tu `APP_PORT`. Completa el administrador, base
de datos y datos de empresa/tratamientos reales. El instalador prepara una web
vacía; los ejemplos son opcionales. Configura idiomas y mercados y revisa las
páginas legales y el consentimiento antes de publicar contenido.

## 3. Personalizar y verificar

El código propio va en `app/` con namespace `App`. Las vistas y assets propios
van en `resources/`; utiliza overrides o un tema independiente. No edites `vendor/`.
[Extensiones y Blade](EXTENSIONS.md) define rutas de overrides, páginas Blade,
componentes compartidos, publicación, privacidad e integración de módulos.

```bash
./vendor/bin/sail npm run dev
./vendor/bin/sail composer test
./vendor/bin/sail composer check
```

`npm run dev` permanece abierto: ejecuta los otros comandos en otra terminal.
Para una comprobación de producción, usa `./vendor/bin/sail npm run build`.
No confundas guardar un borrador con publicarlo; verifica la URL anónima en el
idioma y mercado correctos. Revisa el diff y los lockfiles antes de cada commit.

## 4. Añadir módulos, bloques o temas

Por ejemplo, para incorporar Blog:

```bash
./vendor/bin/sail composer require dbravoan/dbcms-module-blog:^1.0
./vendor/bin/sail npm run build
```

Después instala y activa Blog desde **Módulos**, configura sus permisos y su
tratamiento de datos cuando corresponda. Composer descarga código y dependencias;
el CMS instala y activa sus contribuciones. Un tema descargado también debe
seleccionarse explícitamente. Los elementos desactivados conservan datos e instancias.

Para retirar un módulo, revisa dependientes, desactívalo y desinstálalo desde el
CMS antes de eliminar su dependencia Composer. Recompila assets y comprueba el
resultado. No borres datos como consecuencia implícita de quitar código.

## 5. Actualizar sin sincronizar todo

Lee las notas del paquete y ensaya con una copia desechable de base de datos y
archivos. Haz una copia recuperable antes de modificar una instalación real.
Ejemplo de actualización selectiva:

```bash
./vendor/bin/sail composer update dbravoan/dbcms-module-blog --with-dependencies
./vendor/bin/sail npm ci
./vendor/bin/sail npm run build
./vendor/bin/sail composer test
./vendor/bin/sail composer check
```

Revisa qué dependencias cambiaron y confirma `composer.lock`. El ejemplo supone
una instalación existente; un proyecto nuevo utiliza el instalador. Composer
rechaza combinaciones incompatibles. No hace falta actualizar un tema para
corregir otro módulo. Los cambios incompatibles requieren revisar restricciones,
adaptar código y repetir el ensayo; no fuerces la resolución ignorando requisitos.

## 6. Subir y desplegar

Guarda código y lockfiles en tu repositorio, manteniendo fuera `.env`, claves,
datos y exports privados. El despliegue del starter está desactivado por defecto.
Si encaja con tu VPS, sigue [Despliegue opcional](DEPLOYMENT.md); también puedes
sustituirlo por el procedimiento de tu equipo. Cada proyecto es responsable de
su infraestructura, copias de seguridad, servicios y recuperación.
