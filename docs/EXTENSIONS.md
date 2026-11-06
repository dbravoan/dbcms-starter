# Extensiones y Blade

El [contrato de arquitectura](../specs/CORE_AND_EXTENSIONS.md) define propietarios
y disponibilidad. Composer descarga y versiona código; el CMS instala y activa
contribuciones explícitamente. No se ejecuta un gestor de paquetes desde HTTP.
Para incorporar extensiones a una web, sigue [Crear proyectos](PROJECTS.md).

## Contratos de paquetes

| Contribución | Tipo Composer | Ejemplo |
| --- | --- | --- |
| Módulo de negocio | `dbcms-module` | `dbravoan/dbcms-module-blog` |
| Bloques visuales | `dbcms-block-package` | `dbravoan/dbcms-blocks-basic` |
| Tema público | `dbcms-theme` | `dbravoan/dbcms-theme-db-cyber` |
| Tema administrativo | `dbcms-admin-theme` | `dbravoan/dbcms-admin-theme-dbcms` |

Declara dependencias en `require`, namespaces en `autoload.psr-4` y contribuciones
en `extra.dbcms`. Cada contribución necesita `identifier` único. Los módulos
declaran su `provider`; los paquetes visuales, sus clases de bloques.
`DbCms\Core\Extensions\ComposerPackages` lee el inventario instalado de Composer,
sin explorar directorios arbitrarios ni escribir estado. `module.json` contiene
ajustes y contribuciones, no otro resolvedor de versiones: no puede sustituir
las dependencias de Composer. Los proveedores pueden utilizar namespaces de terceros
y deben residir en su paquete. Las versiones publicadas/desarrollo siguen Composer.

Cada paquete tiene su propio versionado y expresa compatibilidad mediante `require`.
Un módulo `1.x` puede requerir core `^1.0`; no se sincronizan sus números. Véase
[Publicación](PUBLICATION.md) para tags y distribución.

Ejemplo mínimo:

```json
{
  "name": "acme/dbcms-events",
  "type": "dbcms-module",
  "require": {
    "dbravoan/dbcms-core": "^1.0"
  },
  "autoload": {
    "psr-4": {
      "Acme\\Events\\": "./"
    }
  },
  "extra": {
    "dbcms": {
      "identifier": "events",
      "name": "Events",
      "provider": "Acme\\Events\\EventsServiceProvider"
    }
  }
}
```

Sitúa el proveedor en la raíz del paquete si extiende
`DbCms\Core\Modules\BaseModuleServiceProvider`: sus rutas administrativas se
resuelven respecto a `Routes/admin.php`. La base aporta autenticación y
disponibilidad; cada ruta sigue necesitando sus permisos de recurso. Registra
proveedores mediante metadatos dbCMS, no descubrimiento Laravel que omita el ciclo
de vida del módulo.

Usa paquetes existentes como ejemplos de propietario: migraciones, entidades,
ajustes, lectores públicos, navegación y capacidades pertenecen a su módulo.
Una entidad con revisión editorial registra su esquema/handler en las mutaciones
compartidas. URLs, búsqueda y descubrimiento semántico son explícitos; un esquema
administrativo no vuelve públicos modelos privados. Las mutaciones relacionadas
son transaccionales y los efectos remotos se emiten después del commit.

Tras `composer require` mediante Sail, recompila assets e instala/activa desde
**Módulos**. Desactiva/desinstala antes de quitar una dependencia Composer. Los
datos se conservan salvo una operación separada autorizada. La disponibilidad usa
`ModuleManager::isModuleEnabled()`; las instancias desactivadas se preservan.
Paquetes gratuitos, privados y de pago comparten contrato y autenticación Composer;
la política de descarga pertenece al servicio de distribución.

## Bloques y contenido público

Un bloque extiende `DbCms\Core\Blocks\AbstractBlockType` y define tipo estable,
esquema/validación de editor, valores iniciales, rutas traducibles y render.
Un módulo registra mediante `BlockRegistryInterface::register()` y declara
`getRequiredModule()`. Un paquete visual enumera clases en `extra.dbcms.blocks`.
Todos comparten registro y decisión de disponibilidad.

Mantén consultas en el lector público propietario. Aplica publicación, idioma,
mercado y disponibilidad antes de seleccionar datos. `PublicSemanticRegistry`
acepta contribuidores semánticos/URL explícitos. Un bloque implementa
`PublicWidgetSemanticContributorInterface` solo si aporta texto público. Búsqueda
y SEO consumen estos lectores y no ejecutan Blade arbitrario para extraer texto.

## Catálogo para asistentes y medios

`cms_block_types` expone el catálogo del núcleo para `entity_type`, `locale` y
`market`; admite `entity_id` y `block_type` para limitar la consulta. Devuelve los
bloques activos, sus esquemas editoriales anidados, disposición, rutas traducibles
y referencias contextuales. No exige AiAssistant. El actor necesita acceso a la
entidad; las páginas Blade no admiten edición de secciones. Consultar el catálogo
no instala ni activa contribuciones.

Los bloques dinámicos implementan
`DbCms\Core\Blocks\Contracts\ContextualBlockReferencesInterface` para aportar
referencias válidas en el mercado e idioma seleccionados mediante sus lectores
propietarios. El asistente y MCP consumen el mismo catálogo; no se deben usar
consultas del editor sin contexto ni interpretar los ejemplos como datos reales.
Las mutaciones vuelven a comprobar disponibilidad, esquema y referencias.

La biblioteca admite subida de archivos y, con `cms_media_import`, importación de
imágenes desde URL pública. `cms_media_upload` recibe `filename` y
`content_base64`; importar recibe `url`, `title` y `alt_text` opcionales. Ambas
operaciones requieren `manage:media` y funcionan sin AiAssistant. Las imágenes
se guardan en el almacenamiento configurado, con contenido validado y límite de
50 MB. Las URLs remotas no pueden contener credenciales, resolver a redes privadas
ni depender de redirecciones. La URL final pertenece a la biblioteca, no al
proveedor generativo. Subir o generar una imagen no publica contenido.

## Vistas, temas y assets

Un tema público contiene `theme.json`, `layouts/app.blade.php`, overrides y
`theme.css`. Un tema admin contiene su manifest, vistas de marca y assets. La
versión procede de Composer, no de un campo paralelo en `theme.json`.
El entorno selecciona identificadores instalados mediante `CMS_THEME` y `CMS_BRAND`.
Cada tema aporta su layout, sin fallback implícito a otro tema.

La resolución es override del proyecto, tema seleccionado y vista del propietario.
Los overrides públicos residen en `resources/views/themes/<theme-id>/`, expuestos
mediante `theme-<theme-id>::`. Los overrides Laravel de módulos residen en
`resources/views/vendor/<namespace>/`. Usa
`DbCms\Core\Services\Cms\FrontViewResolver`, sin duplicar la resolución.
Los controles admin compartidos usan `<x-admin.*>` semánticos; conserva etiquetas,
teclado y las marcas instaladas.

Vite compila paquetes instalados y assets propios. Ejecuta
`./vendor/bin/sail npm run build` tras cambios de paquetes. Mantén fuentes e imágenes
predeterminadas locales y no escribas compilados en vendor. Las personalizaciones
pertenecen a assets/vistas del proyecto o a un tema requerido por separado.

## Variables opcionales hacia el tema admin

Los temas admin (`admin.layout` y vistas `admin.*`) pueden recibir variables de
vista opcionales que un módulo o el núcleo aportan con `View::composer` o en el
DTO de la vista. No forman parte del contrato de [núcleo y extensiones](../specs/CORE_AND_EXTENSIONS.md);
son convenciones de presentación. Pintarlas solo cuando existan / tengan valor.

| Variable | Tipo | Quién la aporta | Cuándo se pinta |
| --- | --- | --- | --- |
| `inactive` | `bool` | Núcleo (`ModuleSettingsAdministrationService`) en ajustes de módulo | Aviso en el layout admin si el módulo está instalado pero no activo |
| `modulePrivacyWarnings` | `array<string, array{message: string, label: string}>` | Módulo (p. ej. content-audit en `admin.modules.index`) | Enlace a `admin.settings.privacy` junto al módulo cuando falta su tratamiento |
| `config('cms.adminer_url')` | `string` (config, no variable de vista) | Proyecto / entorno | Enlace Adminer en el layout admin fuera de producción, mismo patrón `@if(... && config('cms.adminer_url'))` |

Ejemplo (aviso de módulo inactivo en el layout):

```blade
@if(! empty($inactive))
    <p role="status">…</p>
@endif
```

Ejemplo (aviso de privacidad en el listado de módulos):

```blade
@if(isset($modulePrivacyWarnings[$module->identifier]))
    <a href="{{ route('admin.settings.privacy', ['owner' => $module->identifier]) }}">
        {{ $modulePrivacyWarnings[$module->identifier]['label'] }}
    </a>
@endif
```

La configuración de privacidad del panel (`admin.settings.privacy`) también es
alcanzable desde Ajustes del sitio. No rellenes variables de layout huérfanas
si la UI ya enlaza esa ruta.

## Páginas Blade

Registra vistas controladas por código en `config/cms.php` del proyecto:

```php
return [
    'page_views' => ['landing' => 'pages.landing'],
];
```

Crea `resources/views/pages/landing.blade.php` y selecciona `blade:landing` en
la página del panel. `PageViewRegistry` solo permite claves registradas, reserva
las vistas legales y falla explícitamente si falta una vista. Page sigue siendo
propietaria de traducciones, mercados, permisos, publicación y snapshots.
Las secciones existentes permanecen almacenadas, sin edición ni render en modo Blade.

Los campos públicos usan la traducción del mercado solicitado y, si está vacía,
la fila global del mismo idioma. Nunca otro mercado o idioma. Un slug regional
prevalece en ese mercado; enlaces, búsqueda, sitemap, texto semántico y secciones
usan el mismo contexto. Las traducciones y snapshots conservan sus filas originales.

Dentro de una vista registrada puedes reutilizar bloques de módulos instalados:

```blade
@extends(app(\DbCms\Core\Services\Cms\FrontViewResolver::class)->layout())

@section('content')
    <x-cms::block type="widget_posts"
        :payload="['selection' => 'latest', 'limit' => 3]" />
    <x-cms::block type="widget_form"
        :payload="['form_slug' => 'contact']" />
@endsection
```

El ejemplo necesita Blog y Forms activos y un formulario público `contact`.
El componente valida payload y utiliza los mismos lectores, disponibilidad e
idioma/mercado que el render de secciones. No evita sus controles.

Para páginas por ruta, usa rutas Laravel normales con middleware `cms.front`.
Aporta contexto público, no otro router ni publicación automática. El controlador
personalizado responde de la autorización. Blade no tiene caché HTML de página
completa por defecto, conservando CSRF/sesión por petición. Un documento completo
incluye `@include('themes::components.cookie-consent-modal')`.

## Contribuciones de privacidad

Los embeds ejecutables declarados usan entradas `privacy.external_services` con
`provider`, `purpose` y `origins` HTTPS exactos. Su tratamiento revisado pertenece
a `external_<service-id>` y describe datos, base jurídica, destinatarios,
transferencias y conservación. Selecciona el servicio en Video/Code Embed.
Las URLs no declaradas permanecen no disponibles y los embeds declarados inertes
hasta obtener consentimiento de contenido externo. Code Embed limita también su
sandbox a los orígenes declarados. Cambiar proveedor/origen cambia la revisión.

CSP limita imágenes, medios y fondos CSS al origen del sitio. Los servicios de
hosting/CDN necesarios se declaran en `privacy.asset_services` con la misma forma
y tratamiento revisado `assets_<service-id>`. No utilices esa vía para seguimiento.
Los orígenes opcionales solo se permiten con recibo vigente. Cambiar una opción
recarga el documento para aplicar CSP y detener scripts de terceros anteriores.

Implementa `DbCms\Core\Security\Contracts\CookieDisclosureContributorInterface`
para describir almacenamiento e integraciones efectivos. Registra con la etiqueta
`cms.cookie-disclosures`; `revisionData()` contiene destinos públicos efectivos,
sin credenciales. No aportes información/revisión opcional si el módulo o
integración no está disponible. La necesidad/opcionalidad pertenece al servicio
compartido, no a parsers de cookies específicos por módulo.

`CookieConsentService::hasConsent($purpose, $request)` decide en servidor para
la petición actual. Scripts, contenido externo y seguimiento opcionales esperan
consentimiento; los trabajos vuelven a comprobar autorización. Usa UI y endpoints
compartidos, no otro banner. Los workers transportan el ID opaco del recibo y
llaman `hasConsentForReceipt` antes de enviar. Caducidad, retirada o revisión de
política lo invalidan. `consentReceiptId` opcional de Meta CAPI utiliza ese lector.

`LegalPageService` posee información de responsable/empresa y tratamientos.
El instalador crea páginas legales localizadas y enlaces de pie. La pantalla de
privacidad del panel permite revisar los datos y tratamientos existentes; el
responsable confirma que corresponden a la instalación. Para automatización,
ejecuta `privacy:configure <file>` mediante Sail conforme a `LegalCompanyDTO`, con
la lista completa de tratamientos; el archivo privado no entra en Git. Ambas vías
sincronizan la conservación y la rotación de logs; el formulario general solo
modifica contacto/empresa.
Un idioma nuevo necesita traducciones legales completas antes de activarlo.

El tratamiento obligatorio `core` declara `retention_days` positivo para metadatos
de seguridad, notificaciones e historiales terminados. Instalación y configuración
de privacidad fijan rotación diaria. Configura el scheduler: `privacy:prune`
retira registros vencidos, logs locales fechados y tokens, sesiones, restablecimientos
y trabajos vencidos/finalizados. Correo en curso y trabajo pendiente requieren
revisión. Logs externos y backups necesitan su propio ciclo coherente.

`accounts:privacy export <id> --verified` exporta a almacenamiento local privado;
`erase` revoca credenciales y retira copias de contacto/sesión del núcleo. Borra
exports tras atender la solicitud. Verifica identidad, alcance y conservación antes
de usar `--verified`: el flag no realiza esa revisión. Se protegen el último admin
humano, trabajo en curso y referencias de autor de módulos. Los propietarios
correspondientes gestionan sus datos. El registro API público requiere tratamiento
`accounts` revisado. La conservación de cuentas usa criterio documentado con
`manual_review: true`, sin `retention_days`, porque no se borran cuentas activas
automáticamente. Los formularios propios muestran
`<x-cms::privacy-notice owner="accounts" :allow-manual-review="true" />` antes de recoger datos.

Los módulos con datos personales poseen exportación, borrado y conservación,
incluso desactivados. Consulta los README de Forms, Shop y Blog para sus comandos.
Configura fines reales, bases jurídicas, destinatarios, transferencias y retención.
Las páginas generadas no certifican cumplimiento; adapta otras jurisdicciones.

Verifica instalación real, propietarios ausentes/desactivados, ambas marcas admin,
overrides, publicación/localización y privacidad según [Pruebas](TESTING.md).

### Previsualización editorial

Los esquemas de entidades auditables pueden declarar `previewHandler`, una clase
que implementa `EditorialPreviewHandlerInterface`. Recibe el modelo hidratado
con el snapshot y el contexto de mercado e idioma y devuelve `FrontPageData`.
El propietario prepara su vista a partir de las relaciones hidratadas, sin
consultar de nuevo la entidad publicada. La previsualización es privada y de
solo lectura; el tema y los contenidos relacionados reflejan el contexto actual.
