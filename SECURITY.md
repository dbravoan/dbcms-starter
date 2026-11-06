# Política de seguridad

## Versiones con soporte

| Versión | Estado de soporte |
| --- | --- |
| 1.x | Soportada (línea completa de los paquetes del producto 1.0.0) |
| < 1.0 | No soportada |

Las correcciones de seguridad se dirigen a las versiones **1.x** mantenidas de los
paquetes afectados (núcleo, módulos, bloques, temas, temas admin y starter).
No hay soporte para líneas anteriores a `1.0.0`. Las ramas de desarrollo son
versiones preliminares. La versión de un módulo o tema no tiene por qué coincidir
con la del núcleo; cada paquete versiona de forma independiente (véase
[Publicación](docs/PUBLICATION.md)).

## Comunicar una vulnerabilidad

No comuniques vulnerabilidades mediante incidencias públicas de GitHub. Envía
un correo privado a **hola@davidbravo.com.es** con la descripción, pasos de
reproducción o prueba de concepto, paquete y versión afectados y posibles medidas
de corrección. Incluye integraciones, endpoints y configuración pertinentes;
no adjuntes credenciales ni datos personales reales innecesarios.

Los objetivos de respuesta del mantenedor son un acuse en 48 horas, evaluación de
impacto y corrección en 30 a 90 días según gravedad y complejidad. Son objetivos,
no garantías del runtime ni del CI. La divulgación coordinada puede incluir un
aviso de seguridad junto con la versión corregida.
