# Núcleo y extensiones

Este es el contrato canónico de arquitectura. Las aplicaciones Laravel consumen
dbCMS mediante Composer. El código del proyecto pertenece a `App`; el CMS
reutilizable a `DbCms\Core`. Módulos opcionales, temas públicos/admin y paquetes
de bloques son dependencias Composer. No se edita vendor; las actualizaciones
llegan mediante Composer y los tags publicados de cada paquete.

## Responsabilidades y ciclo de vida

El núcleo posee instalación, identidad/permisos, localización, medios, páginas,
menús, publicación, secciones, resolución de temas, SEO técnico y privacidad.
Los módulos poseen sus entidades, migraciones, rutas, navegación, capacidades y
operaciones sobre datos personales. Los componentes admin compartidos pertenecen
al núcleo; la presentación de marca a los temas admin. El catálogo de negocio se conserva.

Composer gestiona versiones, dependencias y autoload. Los metadatos CMS describen
contribuciones. Descubrir paquetes instalados no escribe estado. La instalación
explícita ejecuta las migraciones seleccionadas y registra estado. Disponibilidad,
instalación y activación son distintas. Desactivar conserva datos y rechaza
dependientes activos; desinstalar rechaza dependientes instalados. Las contribuciones
públicas desactivadas no ejecutan, consultan, aparecen en selectores ni aportan semántica.

Cada paquete tiene versionado independiente. Núcleo, starter y extensiones comienzan en 1.x. Las restricciones Composer expresan compatibilidad, no igualdad
de versiones. Los tags publicados son la fuente de versiones; los repositorios
`path` pertenecen únicamente al workbench. Véase [Publicación](../docs/PUBLICATION.md).

Bloques y widgets comparten registro y decisión de disponibilidad. Basic, Charts
(incluidos KPI/ROI) y BeforeAfter son paquetes Composer. Los paquetes nuevos
comienzan desactivados; el instalador habilita explícitamente su composición.
Las instancias desactivadas se conservan como elementos no disponibles y se
recuperan al activar. Los cambios de disponibilidad reindexan sincrónicamente en
su transacción y reinician workers después del commit. Descubrir no hace ninguna
de las dos cosas. No se añaden registros duplicados ni autoloaders propios.

## Presentación y páginas

La resolución prioriza override del proyecto, tema seleccionado y vista del
propietario. Cada tema posee su layout; no hay fallback implícito entre temas.
Vite compila assets de paquetes instalados y overrides sin escribir en vendor.
Las fuentes e imágenes predeterminadas son locales.

La plantilla Page `blade:<key>` resuelve una vista registrada en código, nunca una
ruta arbitraria proporcionada por un editor. Pages conserva publicación,
traducciones, aislamiento de idiomas/mercados, permisos, SEO y snapshots. El modo
Blade conserva secciones latentes, rechaza sus ediciones y las excluye de la
semántica pública. Los snapshots siguen capturando/restaurando secciones canónicas.
Una vista registrada ausente falla explícitamente, sin volver silenciosamente a
secciones. Las páginas Blade por ruta usan rutas Laravel con contexto público CMS,
sin un segundo router.

`<x-cms::block type="…" :payload="…" />` usa registro, validación, disponibilidad
y lectores públicos compartidos con el render de secciones. Blade puede incluir
noticias vivas y formularios; no tiene caché HTML de página completa por defecto.
La búsqueda nunca ejecuta Blade arbitrario para extraer contenido. Los formularios
conservan CSRF y estado de la petición. Un documento completo personalizado incluye
el componente compartido de privacidad.

## Privacidad por defecto

La instalación recoge datos reales de empresa/responsable y crea aviso legal,
privacidad y cookies localizados mediante vistas Blade reservadas. Los datos
legales tienen una única fuente y las versiones de política describen tratamientos
reales configurados. La referencia suministrada es España/UE:
[RGPD](https://eur-lex.europa.eu/eli/reg/2016/679/oj),
[LOPDGDD](https://www.boe.es/eli/es/lo/2018/12/05/3/con),
[LSSI](https://www.boe.es/eli/es/l/2002/07/11/34/con) y
[guía de cookies AEPD](https://www.aepd.es/guias/guia-cookies.pdf).
La privacidad técnica estricta se aplica a todos los mercados; otras jurisdicciones
requieren adaptación. Las páginas generadas no certifican cumplimiento legal.

Un mecanismo del núcleo gestiona información y consentimiento en navegador y
servidor. Los fines opcionales comienzan denegados. El consentimiento tiene revisión
y caducidad; aceptar, rechazar y retirar son accesibles. Scripts, embeds, posters
y seguimiento externos opcionales esperan autorización; los trabajos vuelven a
comprobarla antes de enviar. Solo el almacenamiento necesario no requiere petición
de consentimiento opcional. La información refleja configuración y almacenamiento
efectivos. No se añaden parsers de cookies por módulo.

Los formularios muestran información contextual y separan marketing opcional.
No se exige consentimiento si corresponde otra base jurídica. Se minimizan datos,
incluidos IP/UA. Cada propietario implementa conservación y derechos autorizados,
incluso para datos retenidos tras desactivar. Se respetan restricciones justificadas
de conservación. No hay motor universal de cumplimiento ni afirmaciones falsas
de anonimato o conformidad.

## Mutaciones y verificación

Los controladores validan, delegan y responden. Los servicios de dominio deciden,
gestionan transacciones y efectos externos posteriores al commit. Las interfaces
representan fronteras reales de sustitución; los DTO representan entradas/salidas
con significado. No se añaden wrappers de reenvío ni cuotas de tamaño de archivos.
Se aplica PHP estricto, Pint y PHPStan nivel 8 sin exclusiones de línea base.

Los snapshots editoriales usan esquema 3. Preparar borradores conserva datos vivos;
las aprobaciones rechazan hashes obsoletos; los tokens vinculan actor, destino y
contenido. Restaurar es transaccional y conserva filas canónicas completas y
relaciones de módulos. No se mantienen alias heredados permanentes.

Usa Composer/npm, Sail oficial y comprobaciones Docker aisladas; no Make ni comandos
`bin/` propios. No hay CI automático en pushes ni PR del monorepo; las comprobaciones
son locales, manuales y obligatorias antes de publicar. El despliegue pertenece a
cada proyecto; el ejemplo VPS opcional del starter no impone su layout al núcleo.
Las pruebas que modifican instalación usan archivos y bases de datos desechables.
Protege secretos, claves y datos de trabajo. Véase [Pruebas](../docs/TESTING.md).
