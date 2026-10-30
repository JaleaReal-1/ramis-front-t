/// API Configuration - Centralizada para todo el backend
///
/// NOTA IMPORTANTE: Esta es la ÚNICA ubicación donde debe configurarse la URL base.
/// Todos los servicios/repositorios deben importar esto.
///
/// Para cambiar la URL:
/// - Editar esta variable: apiBaseUrl
/// - NO modificar en múltiples archivos de servicio
///
/// Uso:
/// ```dart
/// final baseUrl = ApiConfig.baseUrl;
/// ```

class ApiConfig {
  /// URL BASE del servidor backend
  /// Cambiar aquí cuando se redeploys el backend en diferente host/IP
  ///
  /// Opción LAN (Wi-Fi/red local): apunta a la IP de la PC donde corre el
  /// backend. El celular debe estar en la misma red. Usar `ipconfig` para
  /// verificar la IP actual de la PC (ej. 192.168.18.48).
  static const String baseUrl = 'https://18.230.184.228.sslip.io';

  /// Timeout para conexiones HTTP (segundos)
  static const int connectTimeout = 15;
  static const int receiveTimeout = 15;

  /// Endpoints - Transporte
  static const String endpointVehiculos = '/api/vehiculos';
  static const String endpointRutas = '/api/rutas';
  static const String endpointInspecciones = '/api/inspecciones';
  static const String endpointAverias = '/api/averias';
  static const String endpointIncidentes = '/api/incidentes';
  static const String endpointMantenimientos = '/api/mantenimientos';
  static const String endpointJornadas = '/api/jornadas';

  /// Endpoints - Otros módulos
  static const String endpointAuth = '/api/auth';
  static const String endpointUsuarios = '/api/usuarios';

  /// Endpoint de login
  static String getLoginUrl() => '$baseUrl$endpointAuth/login';

  /// Endpoints para Vehículos
  static String getVehiculosUrl() => '$baseUrl$endpointVehiculos';
  static String getVehiculoUrl(int id) => '$baseUrl$endpointVehiculos/$id';

  /// Endpoints para Rutas
  static String getRutasUrl() => '$baseUrl$endpointRutas';
  static String getRutaUrl(int id) => '$baseUrl$endpointRutas/$id';
  static String getIniciarRutaUrl(int id) =>
      '$baseUrl$endpointRutas/$id/iniciar';
  static String getFinalizarRutaUrl(int id) =>
      '$baseUrl$endpointRutas/$id/finalizar';

  /// Endpoints para Inspecciones
  static String getInspeccionesUrl() => '$baseUrl$endpointInspecciones';
  static String getInspeccionUrl(int id) => '$baseUrl$endpointInspecciones/$id';
  static String getCrearInspeccionSalidaUrl() =>
      '$baseUrl$endpointInspecciones/salida';
  static String getCrearInspeccionLlegadaUrl() =>
      '$baseUrl$endpointInspecciones/llegada';

  /// Endpoints para Averías
  static String getAveriasUrl() => '$baseUrl$endpointAverias';
  static String getAveriaUrl(int id) => '$baseUrl$endpointAverias/$id';
  static String getAveriasVehiculoUrl(int vehiculoId) =>
      '$baseUrl$endpointAverias/vehiculo/$vehiculoId/historial';

  /// Endpoints para Incidentes
  static String getIncidentesUrl() => '$baseUrl$endpointIncidentes';
  static String getIncidenteUrl(int id) => '$baseUrl$endpointIncidentes/$id';
  static String getIncidentesVehiculoUrl(int vehiculoId) =>
      '$baseUrl$endpointIncidentes/vehiculo/$vehiculoId/historial';

  /// Endpoints para Mantenimientos
  static String getMantenimientosUrl() => '$baseUrl$endpointMantenimientos';
  static String getMantenimientoUrl(int id) =>
      '$baseUrl$endpointMantenimientos/$id';
  static String getCrearMantenimientoCorractivoUrl() =>
      '$baseUrl$endpointMantenimientos/correctivo';
  static String getCrearMantenimientoPreventivoUrl() =>
      '$baseUrl$endpointMantenimientos/preventivo';
  static String getEjecutarMantenimientoUrl(int id) =>
      '$baseUrl$endpointMantenimientos/$id/ejecutar';
  static String getMantenimientosVehiculoUrl(int vehiculoId) =>
      '$baseUrl$endpointMantenimientos/vehiculo/$vehiculoId/historial';
  static String getMantenimientosVencidosUrl() =>
      '$baseUrl$endpointMantenimientos/reportes/vencidos';
  static String getMantenimientoAlertasUrl() =>
      '$baseUrl$endpointMantenimientos/alertas';

  /// Endpoints de jornadas de transporte
  static String getAsignarJornadaUrl() => '$baseUrl$endpointJornadas/asignar';
  static String getChecklistInicialUrl(int jornadaId) =>
      '$baseUrl$endpointJornadas/$jornadaId/checklist-inicial';
  static String getIncidenciasJornadaUrl(int jornadaId) =>
      '$baseUrl$endpointJornadas/$jornadaId/incidencias';
  static String getChecklistFinalUrl(int jornadaId) =>
      '$baseUrl$endpointJornadas/$jornadaId/checklist-final';

  /// Endpoints para Checklist e Inspecciones
  static String getChecklistItemsUrl() =>
      '$baseUrl$endpointInspecciones/checklist-items';
  static String getInspeccionVehiculoHistorialUrl(int vehiculoId) =>
      '$baseUrl$endpointInspecciones/vehiculo/$vehiculoId/historial';
  static String getInspeccionVehiculoUltimaUrl(int vehiculoId) =>
      '$baseUrl$endpointInspecciones/vehiculo/$vehiculoId/ultima';
}
