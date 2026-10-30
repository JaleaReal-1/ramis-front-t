# Guion para presentar las mejoras de Transportes V3

**Duración estimada:** 5 minutos
**Objetivo:** explicar las mejoras implementadas y mostrar el flujo completo desde el celular.

## Apertura

> El objetivo de estas mejoras fue llevar la gestión de transportes al celular. Ahora el conductor puede consultar y regularizar sus documentos desde su propia pantalla, mientras que el administrador puede revisar conductores, controlar la documentación de la flota y obtener la ficha técnica de cada vehículo.

## Mejoras para el conductor

> Añadimos la pestaña **Mis Documentos**. Allí el conductor ve su licencia, examen médico ocupacional y pase minero. Cada documento muestra su vencimiento, los días restantes, un semáforo y el estado de revisión: pendiente, aprobado o rechazado. También puede abrir el archivo que subió.

> Si necesita regularizar un documento, elige el tipo, indica la fecha de vencimiento y adjunta una foto tomada con la cámara, una imagen de la galería o un PDF. Si pierde la señal, la solicitud queda en una cola local para enviarse cuando vuelva la conexión.

## Mejoras para el administrador

> El administrador tiene una nueva vista de **Conductores**. Puede buscar a cada persona, ver el estado de sus tres documentos, aprobar o rechazar una solicitud con un motivo, configurar su acceso con correo y contraseña inicial, y dar de alta rápidamente a un conductor con DNI, nombres y apellidos.

> En **Flota**, al abrir un vehículo aparece su detalle operativo y documental: SOAT, revisión técnica, póliza, tarjeta de propiedad y pase minero de la unidad. Desde allí se pueden actualizar documentos y descargar la ficha técnica en PDF. También se incorporó el alta rápida de vehículos.

## Flujo completo para explicar

1. El administrador registra al conductor y al vehículo.
2. El conductor ingresa a **Mis Documentos** y carga los archivos requeridos.
3. El administrador revisa cada solicitud y la aprueba o rechaza con un motivo.
4. Al aprobarla, el sistema actualiza la vigencia correspondiente.
5. Los semáforos permiten identificar documentos vigentes, próximos a vencer o vencidos.
6. El administrador consulta el detalle de la unidad y descarga su ficha técnica en PDF.

> Los accesos a estas funciones están visibles en el menú de cada rol, para que el flujo se pueda realizar directamente desde el celular.

## Cierre y estado de validación

> La implementación pasó el análisis de Flutter sin incidencias, **30 pruebas móviles** y **13 pruebas de backend**. El APK de prueba compiló correctamente. Antes de hacer una demostración en vivo, conviene comprobar en el teléfono la cámara, el selector de archivos y la apertura del PDF, porque esos pasos todavía no se verificaron manualmente en un dispositivo.

## Orden sugerido para la demostración

**Mis Documentos → subir un documento → revisión en Conductores → detalle de Flota → ficha PDF.**
