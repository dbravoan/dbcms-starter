# Mi proyecto dbCMS

Esta plantilla crea una aplicación Laravel que consume paquetes dbCMS publicados
en la línea **1.x** (`^1.0`). No contiene el catálogo de desarrollo. El código
propio pertenece a `App`; los paquetes instalados residen en `vendor/` y no se
modifican directamente.

## Empezar paso a paso

Sigue [Crear y mantener una web](docs/PROJECTS.md): requisitos Git/Docker, descarga
mediante Composer o plantilla GitHub, dependencias, Sail, configuración, assets,
instalador, personalización, módulos y actualizaciones. Los comandos ejecutan PHP,
Composer y Node en contenedores; no necesitas PHP instalado en tu equipo.

La composición inicial incluye AiAssistant, ContentAudit y MCP, bloques Basic,
tema público `db-cyber` y tema admin `dbcms` (restricciones Composer `^1.0`).
Los módulos se instalan/activan explícitamente. Los datos de demostración son opcionales.

Conserva `composer.lock` y `package-lock.json` en el repositorio del proyecto.
Nunca publiques `.env`, claves, datos personales ni exports privados. Cada paquete
se versiona de forma independiente a partir de 1.0.0; Composer determina la compatibilidad.

## Guías

Estas rutas relativas existen en la exportación del starter (docs y specs del
monorepo viajan con la plantilla; README/AGENTS se sustituyen por los de
`.github/starter/files`):

- [Extensiones y Blade](docs/EXTENSIONS.md): módulos, temas, bloques y overrides.
- [Pruebas](docs/TESTING.md): comprobaciones y aislamiento.
- [Despliegue opcional](docs/DEPLOYMENT.md): ejemplo VPS; activar solo con
  `DEPLOY_ENABLED=true` (`vars.DEPLOY_ENABLED`).
- [Actualización](docs/UPGRADING.md): instalación limpia; sin upgrade desde versiones previas.
- [Arquitectura](specs/CORE_AND_EXTENSIONS.md) e [instrucciones para agentes](AGENTS.md).
- [Seguridad](SECURITY.md) y [licencia MIT](LICENSE).

Configura tus comprobaciones y tu procedimiento de producción. El ejemplo GitHub
Actions solo se habilita con `DEPLOY_ENABLED=true` y los requisitos documentados.
El monorepo de desarrollo es privado; contacta con los responsables para colaborar.
