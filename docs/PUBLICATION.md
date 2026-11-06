# Publicar paquetes independientes

Esta guía define la distribución, no el despliegue de una web. El monorepo
`dbravoan/dbcms` es la única fuente de desarrollo y es privado. Los repositorios de distribución
reciben únicamente el código de su paquete; las contribuciones se hacen en el
monorepo. El starter se distribuye en `dbravoan/dbcms-starter` con nombre Composer
`dbravoan/dbcms-starter`.

## 1. Preparar GitHub y Packagist

Crea los repositorios de distribución declarados en `extra.dbcms.repository` de
cada paquete y `dbravoan/dbcms-starter`. Configura `RELEASE_TOKEN` en el monorepo
con permisos de escritura sobre esos repositorios. Créelos vacíos, sin README ni
commits iniciales: la acción creará su rama `main`. No guardes tokens en Git.

Cuando el repositorio ya contenga su primera publicación, da de alta
**una entrada por paquete público** en [Packagist](https://packagist.org/packages/submit),
indicando su repositorio de distribución. Su `composer.json` estará en la raíz.
Configura la integración de actualización automática con GitHub. El starter se
registra con el nombre de su manifest, `dbravoan/dbcms-starter`. La entrada
histórica `dbravoan/dbcms` es independiente de esta distribución.

Packagist indexa nombres, dependencias y versiones de los tags; no necesita que
crees manualmente cada versión. Los paquetes privados utilizan distribución y
credenciales Composer estándar. Una web consumidora no necesita entrada Packagist.
Véase la [documentación de Packagist](https://packagist.org/about).

## 2. Catálogo del producto 1.0.0 y SemVer por paquete

El producto **dbCMS 1.0.0** son **31 paquetes**: el núcleo, 17 módulos, 3 paquetes
de bloques, 7 temas públicos, 2 temas de administración y el starter. La lista
canónica con nombre Composer, tipo, versión documental `1.0.0` y enlace al README
está en la sección «Catálogo del producto 1.0.0» del [README raíz](../README.md).

Cada paquete versiona de forma independiente con [Semantic Versioning](https://semver.org/lang/es/)
a partir de `1.0.0`. No existe una versión global del catálogo en `composer.json`:
la fuente de verdad de cada paquete es su tag de distribución (`dbcms-core/vX.Y.Z`,
`dbcms-module-blog/vX.Y.Z`, `starter/vX.Y.Z`, etc.).

Las restricciones `require` entre paquetes dbCMS usan `^1.0` (o el mínimo real
compatible). Un tema `1.0.2` puede requerir core `^1.0`. Una dependencia entre
módulos exige su versión real, normalmente `^1.0`.

Una corrección compatible incrementa patch; una función compatible, minor; una
ruptura del contrato, major. Un cambio de core no obliga a publicar extensiones
que siguen siendo compatibles. Si un módulo necesita una API nueva, aumenta su
requisito mínimo de core y publica el módulo cuando esa dependencia esté disponible.
No declares un campo `version` en `composer.json` ni mantengas otra versión en
`theme.json`: Packagist y Composer leen la versión del tag.

Las versiones `options.versions` del workbench son identidades locales para
resolver el catálogo, no versiones publicadas. Actualízalas por paquete al cambiar
su línea de desarrollo y guarda `workbench/composer.lock` generado con Composer
en contenedor. Las aplicaciones guardan su propio lockfile; el starter distribuido
no contiene el lockfile local del monorepo.

### CHANGELOG

- Cada uno de los **30** paquetes bajo `packages/` mantiene su propio
  [`CHANGELOG.md`](https://github.com/dbravoan/dbcms-core/blob/main/CHANGELOG.md) (Keep a Changelog, castellano),
  con entrada inaugural `[1.0.0]`.
- El [`CHANGELOG.md` raíz](../CHANGELOG.md) es el del **starter/producto**: narra el
  lanzamiento del starter y enlaza el índice 1.0.0 de paquetes con URLs absolutas a
  `…/blob/main/CHANGELOG.md` de cada `extra.dbcms.repository` (opción B).

### Orden concreto de publicación (primer lanzamiento 1.0.0)

Deducción desde los `require` entre paquetes `dbravoan/*` (Composer). Empuja
**como máximo 3 tags por `git push`** (límite de GitHub); espera a que Packagist
resuelva las dependencias antes del siguiente lote.

Cadena obligatoria: **core → marketing/ai-assistant → resto de módulos
(orchestration último) → blocks → themes → admin-themes → starter**.

1. **Núcleo:** `dbcms-core/v1.0.0`
2. **Dependencias base entre módulos** (solo requieren core, y otros módulos las requieren):
   - `dbcms-module-marketing/v1.0.0`
   - `dbcms-module-ai-assistant/v1.0.0`
3. **Resto de módulos** (tras el paso 2; **orchestration el último** de este grupo):
   - Solo core: `dbcms-module-ads`, `dbcms-module-blog`, `dbcms-module-captcha`,
     `dbcms-module-content-audit`, `dbcms-module-forms`, `dbcms-module-gallery`,
     `dbcms-module-maintenance`, `dbcms-module-mcp`, `dbcms-module-meta`,
     `dbcms-module-search`, `dbcms-module-shop` (tags `…/v1.0.0`)
   - Requieren marketing: `dbcms-module-analytics`, `dbcms-module-creative-studio`,
     `dbcms-module-social-publishing`
   - **Último módulo** (requiere ai-assistant): `dbcms-module-orchestration/v1.0.0`
4. **Bloques** (requieren core `^1.0`):
   `dbcms-blocks-basic`, `dbcms-blocks-before-after`, `dbcms-blocks-charts`
5. **Temas públicos** (requieren core `^1.0`):
   `dbcms-theme-db-brutalist`, `dbcms-theme-db-cyber`, `dbcms-theme-db-editorial`,
   `dbcms-theme-db-enterprise`, `dbcms-theme-db-minimal`, `dbcms-theme-db-sunset`,
   `dbcms-theme-default-clean`
6. **Temas admin** (requieren core `^1.0`):
   `dbcms-admin-theme-dbcms`, `dbcms-admin-theme-termocms`
7. **Starter:** `starter/v1.0.0` (requiere core, ai-assistant, content-audit, mcp,
   blocks-basic, theme-db-cyber, admin-theme-dbcms en `^1.0`)

## 3. Verificar el cambio

Sigue [Pruebas](TESTING.md) y revisa el diff, documentación y restricciones de todos
los consumidores. En el monorepo no hay CI automático al subir commits o abrir PR.
Puedes ejecutar la acción manual de comprobación. Publicar siempre verifica el
commit exacto antes de escribir en los repositorios de distribución.

## 4. Publicar solo el paquete seleccionado

Desde el monorepo, con los cambios confirmados en Git, crea un tag de origen y
empújalo. **Hacer push de un tag que coincide con**
`dbcms-*/v*.*.*` o `starter/v*.*.*` **dispara** el workflow
[`.github/workflows/release.yml`](../.github/workflows/release.yml).
Trigger real verificado en el fichero:

```yaml
on:
  push:
    tags: ['dbcms-*/v*.*.*', 'starter/v*.*.*']
  workflow_dispatch:
```

**Push de un tag que coincide con esos patrones = publicar** ese paquete (identidad,
verificación del commit, publicación de `vX.Y.Z` en el repositorio de distribución
y comprobación de instalación desde el registro). También puede lanzarse
manualmente (`workflow_dispatch`) indicando un tag existente e inmutable.

```bash
git tag dbcms-module-blog/v1.0.0
git push origin dbcms-module-blog/v1.0.0
```

Otros ejemplos: `dbcms-core/v1.0.0`, `dbcms-theme-db-cyber/v1.0.0` y
`starter/v1.0.0`. El prefijo de un paquete coincide con la parte posterior a
`dbravoan/` de su nombre Composer; `starter` selecciona la aplicación raíz.

GitHub puede ignorar o limitar empujes con **más de 3 tags** a la vez: publica en
lotes de ≤3 tags y, en el primer lanzamiento, respeta el orden de la sección 2.

La acción identifica un único propietario, comprueba su commit, separa su código
y publica `vX.Y.Z` en el repositorio de distribución. Cada paquete crea o avanza
`main` mediante fast-forward; publicar una versión anterior no hace retroceder esa
rama y una historia ajena se rechaza. Para el starter genera una
exportación reproducible, incorpora `.github/starter/files` y actualiza su
rama principal sin hacerla retroceder. No publica todo el catálogo con el mismo tag.

En un repositorio nuevo no puedes registrar en Packagist un manifest que todavía
no existe. Publica primero el tag de core: cuando termine el job de publicación,
su repositorio tendrá `main`, `composer.json` y el tag. Da entonces de alta el
paquete y configura su integración GitHub. Si la comprobación posterior falló
porque aún no estaba registrado, espera a la indexación y usa **Re-run failed jobs**
para repetirla. Repite ese arranque por paquete siguiendo el orden de dependencias;
para versiones posteriores el hook actualizará la entrada existente.

## 5. Revisar resultado y reintentar

Confirma el tag de distribución y la versión indexada por Packagist. La comprobación
posterior instala esa versión exacta; comprueba también que el starter arranca y
compila sin `packages/`, workbench ni enlaces locales.

Si falla la propagación del registro, reejecuta el mismo workflow. Un tag existente
con los mismos bytes se acepta; con contenido distinto se rechaza. No borres ni
muevas una versión publicada para corregirla: crea una versión nueva. Tampoco
publiques un starter antiguo sobre una rama de distribución más reciente.

Guarda evidencia del commit, paquete, versión, comandos y resultados fuera del
árbol público. Distingue exportación local correcta, tag publicado e instalación
real desde Packagist. La creación de repositorios, credenciales y altas del registro
son pasos externos que el código fuente no acredita por sí mismo.

## Bootstrap inicial (offline)

La fase A solo prepara y exporta contenido local. Usa el script hermano
`bootstrap.mjs`; no utiliza `release.yml` para sembrar distribuciones. Desde la
raíz del monorepo, con Node y Git (incluido `git subtree`) disponibles:

```bash
node .github/scripts/bootstrap.mjs plan --source <SHA-completo-local> --out /ruta/fuera-del-repo/plan.json
node .github/scripts/bootstrap.mjs export --plan /ruta/fuera-del-repo/plan.json --out /ruta/fuera-del-repo/exportacion-nueva
```

El SHA debe tener 40 caracteres e identificar un commit que ya exista en los
objetos Git locales. No hay consultas de red ni recuperación de objetos ausentes.
Los manifests, atributos y overlay se leen siempre en ese SHA: los cambios sin
commit no entran. Para subtree se usa una vista temporal de los objetos locales,
sin clonar ni modificar el index o los directorios del working tree. El archivo de plan y el directorio de exportación deben ser
nuevos; no se sobrescriben. Conserva las evidencias fuera del árbol versionado.

La allowlist revisable `.github/scripts/bootstrap-allowlist.json` contiene los
31 pares exactos de nombre Composer y URL HTTPS de `dbravoan`, contrastados con
los 30 manifests publicables bajo `packages/` y el manifest raíz del starter.
Cualquier cambio de inventario requiere revisar esa lista, no descubre destinos
nuevos automáticamente.

El JSON v1 contiene `schemaVersion: 1`, `sourceCommit` y `entries`, ordenadas por
`composerName`. Cada entrada incluye `composerName`, `repositoryUrl`, `sourcePath`,
`exportKind`, `exportCommit`, `treeOid` y `files`. Cada archivo registra `path`,
`mode` Git y `sha256` de los bytes del blob exportado, sin normalización adicional
de finales de línea; los archivos se ordenan por ruta y los enlaces conservan su
modo y su destino como contenido del blob.

- Los 30 paquetes usan `exportKind: subtree`: el commit es **exactamente** el
  resultado de `git subtree split --prefix=<sourcePath> <S>`, con su ascendencia,
  sin commits propios ni marcador `Source-Commit`. Esto permite que la publicación
  posterior avance por fast-forward.
- Solo el starter usa `starter-snapshot` y `sourcePath: .`: `git archive` con
  `export-ignore`, seguido del overlay `.github/starter/files` de S. Comparte el
  generador de instantáneas con la publicación: commit sin padres, autores dbCMS,
  fecha del commit fuente y mensaje `Starter bootstrap` seguido de
  `Source-Commit: <SHA completo>`. No incluye `packages/` ni el workbench.

Antes de escribir el plan se escanean los blobs exportados: entornos reales,
`auth.json`, claves privadas y patrones de tokens bloquean la operación. Nunca se
imprime el valor detectado. Solo se admiten las plantillas raíz `.env.example` y
`.env.production.example` del starter cuyos hashes están revisados en el script;
los valores sensibles están vacíos o son `null`, salvo el ejemplo local conocido
`DB_PASSWORD=secret` de Sail. Si cambian, deben revisarse y actualizar sus hashes.
No hay una exclusión genérica de tests o fixtures. Este control heurístico no
sustituye la revisión humana; comprueba el árbol final, no todos los commits
históricos del subtree.

`export` recalcula el plan, los commits y todos los hashes, repite el escaneo y
rechaza un plan alterado antes de crear la salida. Guarda `plan.json` y 31
repositorios **locales bare autocontenidos** `<nombre-sin-owner>.git`, con
`refs/heads/main` en el commit verificado, sin remotos, tags ni alternates. Los
objetos se transportan mediante packs locales, sin `fetch` ni `push`. Puedes
inspeccionarlos con `git --git-dir=/ruta/exportacion-nueva/dbcms-core.git show main`
y comprobar integridad con `git --git-dir=... fsck --full`.

Cómo probar sin red (fixtures temporales; no publican nada):

```bash
python3 -m unittest discover -s .github/tests -p '*_test.py'
node --test workbench/tests/Frontend/package-publication.test.mjs
```

La suite Python es la prueba primaria del bootstrap y bloquea comandos de red,
`fetch`, `push` y tags. La suite Node existente comprueba la publicación únicamente
contra repositorios bare temporales. No hay `apply` en esta fase. Crear repositorios
remotos, aplicar/pushear `main`, registrar en Packagist o crear/subir tags requiere
el **OK explícito de David para cada fase**. En particular, no se ha autorizado
`apply`. No se relaja el guard del starter: su primera release posterior debe
partir de R descendiente de S y distinto de S.
