# Trabajar en este proyecto dbCMS

Proyecto consumidor de paquetes **dbCMS 1.x** (`^1.0`). Lee
[Crear proyectos](docs/PROJECTS.md), [Arquitectura](specs/CORE_AND_EXTENSIONS.md)
y [Extensiones](docs/EXTENSIONS.md) antes de cambiar comportamiento. Mantén una
única fuente por regla y documentación en castellano.

## Entorno

- No ejecutes PHP, Composer, Artisan o Pest en el host. Usa Sail oficial; sin
  vendor, sigue el bootstrap Docker PHP 8.4 de la guía de proyectos. En contenedores
  CI/bootstrap ejecuta directamente las herramientas, sin anidar Sail.
- Conserva cambios existentes, `.env`, claves, datos y bloqueos. Las pruebas que
  modifican instalación necesitan archivos y bases de datos desechables:
  `RefreshDatabase` no aísla archivos.
- Composer es responsable de paquetes, versiones (`^1.0` en la composición inicial)
  y autoload. Confirma los lockfiles. No edites vendor ni construyas otro instalador.
  No existe workbench en este proyecto.

## Código

Las personalizaciones pertenecen a `App`, vistas/assets propios u otro paquete.
Los controladores validan, delegan y responden; servicios de dominio deciden y
gestionan transacciones. Prepara datos fuera de Blade y usa controles admin
compartidos. Emite efectos externos después del commit cuando dependan de una
escritura atómica.

Conserva autorización, revisión editorial, publicación, idiomas/mercados y
privacidad en HTTP, MCP, trabajos y vistas. Una contribución desactivada no ejecuta
ni aparece en selectores y conserva sus datos/instancias. No confundas Composer,
instalación y activación del CMS.

Usa PHP estricto, Pint y PHPStan nivel 8 sin exclusiones de línea base. Añade
interfaces para fronteras reales y DTO con significado, evitando wrappers y
registros duplicados. No añadas Make ni comandos `bin/` propios.

## Comprobación y entrega

Sigue [Pruebas](docs/TESTING.md). Informa de comandos, resultados y límites; una
prueba filtrada no acredita la suite completa ni un despliegue real. Guarda
evidencia fechada fuera de directorios públicos. Simula fronteras remotas, no la
decisión verificada, y conserva evidencia de permisos, transacciones y concurrencia.

El [despliegue VPS](docs/DEPLOYMENT.md) es opcional y comienza desactivado
(`vars.DEPLOY_ENABLED`). Configura infraestructura, backups, scheduler y workers
según este proyecto. Nunca regeneres claves existentes ni borres datos como
consecuencia de actualizar paquetes. Cada paquete tiene versión independiente
desde 1.0.0 y sus restricciones Composer deben respetarse.
