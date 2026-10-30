# Interfaz móvil V3 — 24 de octubre de 2026

## Implementación

- Conductor: tercera pestaña «Mis Documentos», licencia, EMO y pase minero; vigencias, categoría, días, semáforo, estado de revisión, motivo de rechazo e historial de archivos.
- Carga documental: formulario adaptable, cámara o galería con reducción de imágenes, PDF y límite de 10 MB. Los PDF se conservan sin recomprimir. Cola persistente por cuenta, reintentos e identificador de solicitud para evitar duplicados.
- Administración: pestaña y acceso en Drawer a Conductores, búsqueda, semáforos, revisión, aprobación/rechazo con motivo, configuración de acceso y alta rápida con apellidos.
- Flota: detalle completo, cinco documentos, actualización, ficha técnica PDF y alta rápida. La configuración de tipo y tanque sigue disponible en el menú de cada unidad.
- Navegación: accesos directos para ambos roles y formularios antiguos V3 convertidos a Scaffold sin anchos fijos de 500/600.

## Backend compatible

Se adaptó el backend local con autorización expresa del usuario: multipart documental para el conductor propietario y el administrador, revisión exclusiva del administrador, listado de conductores, apellidos en alta rápida y rutas de vehículos/PDF bajo `/api/transportes`. Se mantiene la carga JSON administrativa existente.

Las cargas del conductor quedan pendientes; las administrativas se aprueban automáticamente. La aprobación actualiza las vigencias operativas. Los archivos se validan en el servidor; las solicitudes offline se deduplican mediante auditoría. No se requieren columnas ni migraciones nuevas para estos ajustes.

## Verificación

- `flutter analyze lib/features/transportes --no-pub`: sin incidencias.
- `flutter test --no-pub`: 30 pruebas aprobadas, incluidas cuatro pruebas nuevas de interfaz a 360 px y una de persistencia multipart offline.
- Backend: 13 pruebas de integración aprobadas para decisiones V3 y carga/revisión documental, con base de datos aislada.
- Docker: OpenAPI confirma las nuevas rutas tras recargar el servicio.
- APK: `flutter build apk --debug --no-pub`; salida `build/app/outputs/flutter-apk/app-debug.apk`.

La validación de interfaz se realizó con pruebas de widgets; queda pendiente una comprobación manual en dispositivo real de cámara, selector de archivos y apertura del PDF. La compilación conserva avisos del proyecto sobre futuras versiones de Gradle, AGP y Kotlin.
