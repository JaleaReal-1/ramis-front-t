import 'package:dio/dio.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/features/transportes/models/averia_model.dart';
import 'package:sistema_ocs/features/transportes/models/incidente_model.dart';
import 'package:sistema_ocs/features/transportes/models/inspeccion_model.dart';
import 'package:sistema_ocs/features/transportes/models/mantenimiento_model.dart';
import 'package:sistema_ocs/features/transportes/models/ruta_asignacion_model.dart';
import 'package:sistema_ocs/features/transportes/models/vehiculo_model.dart';

class TransportesService {
  TransportesService(this._dio);

  final Dio _dio;

  // =======================
  // VEHÍCULOS
  // =======================
  Future<List<VehiculoModel>> listarVehiculos() async {
    final response = await _dio.get(ApiConfig.endpointVehiculos + '/');
    return _list(response.data, VehiculoModel.fromJson);
  }

  Future<VehiculoModel> obtenerVehiculo(int id) async {
    final response = await _dio.get('${ApiConfig.endpointVehiculos}/$id');
    return VehiculoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VehiculoModel> crearVehiculo(CrearVehiculoRequest request) async {
    final response = await _dio.post(ApiConfig.endpointVehiculos + '/',
        data: request.toJson());
    return VehiculoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VehiculoModel> actualizarVehiculo(
    int id,
    ActualizarVehiculoRequest request,
  ) async {
    final response = await _dio.put(
      '${ApiConfig.endpointVehiculos}/$id',
      data: request.toJson(),
    );
    return VehiculoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminarVehiculo(int id) async {
    await _dio.delete('${ApiConfig.endpointVehiculos}/$id');
  }

  // =======================
  // RUTAS / ASIGNACIONES
  // =======================
  Future<List<RutaAsignacionModel>> listarRutas() async {
    final response = await _dio.get('${ApiConfig.endpointRutas}/');
    return _list(response.data, RutaAsignacionModel.fromJson);
  }

  Future<RutaAsignacionModel> obtenerRuta(int id) async {
    final response = await _dio.get('${ApiConfig.endpointRutas}/$id');
    return RutaAsignacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RutaAsignacionModel> crearRuta(CrearRutaRequest request) async {
    final response = await _dio.post(ApiConfig.endpointRutas + '/',
        data: request.toJson());
    return RutaAsignacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RutaAsignacionModel> actualizarRuta(
    int id,
    ActualizarRutaRequest request,
  ) async {
    final response = await _dio.put('${ApiConfig.endpointRutas}/$id',
        data: request.toJson());
    return RutaAsignacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RutaAsignacionModel> iniciarRuta(
    int id,
    IniciarRutaRequest request,
  ) async {
    final response = await _dio.patch(
      '${ApiConfig.endpointRutas}/$id/iniciar',
      data: request.toJson(),
    );
    return RutaAsignacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RutaAsignacionModel> finalizarRuta(
    int id,
    FinalizarRutaRequest request,
  ) async {
    final response = await _dio.patch(
      '${ApiConfig.endpointRutas}/$id/finalizar',
      data: request.toJson(),
    );
    return RutaAsignacionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminarRuta(int id) async {
    await _dio.delete('${ApiConfig.endpointRutas}/$id');
  }

  // =======================
  // MANTENIMIENTOS
  // =======================
  /// Lista mantenimientos (respuesta simplificada de lista).
  Future<List<MantenimientoListModel>> listarMantenimientos() async {
    final response = await _dio.get('${ApiConfig.endpointMantenimientos}/');
    return _list(response.data, MantenimientoListModel.fromJson);
  }

  /// Historial de mantenimientos de un vehículo.
  Future<List<MantenimientoListModel>> mantenimientosVehiculo(
    int vehiculoId,
  ) async {
    final response =
        await _dio.get(ApiConfig.getMantenimientosVehiculoUrl(vehiculoId));
    return _list(response.data, MantenimientoListModel.fromJson);
  }

  Future<MantenimientoModel> obtenerMantenimiento(int id) async {
    final response = await _dio.get(ApiConfig.getMantenimientoUrl(id));
    return MantenimientoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MantenimientoModel> crearMantenimientoCorrectivo(
    CrearMantenimientoCorreactivoRequest request,
  ) async {
    final response = await _dio.post(
      ApiConfig.getCrearMantenimientoCorractivoUrl(),
      data: request.toJson(),
    );
    return MantenimientoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MantenimientoModel> crearMantenimientoPreventivo(
    CrearMantenimientoPreventivoRequest request,
  ) async {
    final response = await _dio.post(
      ApiConfig.getCrearMantenimientoPreventivoUrl(),
      data: request.toJson(),
    );
    return MantenimientoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MantenimientoModel> actualizarMantenimiento(
    int id,
    ActualizarMantenimientoRequest request,
  ) async {
    final response = await _dio.put(
      ApiConfig.getMantenimientoUrl(id),
      data: request.toJson(),
    );
    return MantenimientoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MantenimientoModel> ejecutarMantenimiento(
    int id,
    EjecutarMantenimientoRequest request,
  ) async {
    final response = await _dio.patch(
      ApiConfig.getEjecutarMantenimientoUrl(id),
      data: request.toJson(),
    );
    return MantenimientoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MantenimientoListModel>> mantenimientosVencidos() async {
    final response = await _dio.get(ApiConfig.getMantenimientosVencidosUrl());
    return _list(response.data, MantenimientoListModel.fromJson);
  }

  Future<void> eliminarMantenimiento(int id) async {
    await _dio.delete(ApiConfig.getMantenimientoUrl(id));
  }

  // =======================
  // INSPECCIONES / CHECKLIST
  // =======================
  Future<List<ChecklistItemModel>> listarChecklistItems() async {
    final response = await _dio.get(ApiConfig.getChecklistItemsUrl());
    return _list(response.data, ChecklistItemModel.fromJson);
  }

  Future<List<InspeccionListModel>> listarInspecciones() async {
    final response = await _dio.get('${ApiConfig.endpointInspecciones}/');
    return _list(response.data, InspeccionListModel.fromJson);
  }

  Future<InspeccionModel> obtenerInspeccion(int id) async {
    final response = await _dio.get(ApiConfig.getInspeccionUrl(id));
    return InspeccionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<InspeccionModel> crearInspeccion(
    CrearInspeccionRequest request,
  ) async {
    final response = await _dio.post(
      ApiConfig.getInspeccionesUrl() + '/',
      data: request.toJson(),
    );
    return InspeccionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<InspeccionListModel>> historialInspeccionesVehiculo(
    int vehiculoId,
  ) async {
    final response =
        await _dio.get(ApiConfig.getInspeccionVehiculoHistorialUrl(vehiculoId));
    return _list(response.data, InspeccionListModel.fromJson);
  }

  Future<InspeccionModel?> ultimaInspeccionVehiculo(int vehiculoId) async {
    final response =
        await _dio.get(ApiConfig.getInspeccionVehiculoUltimaUrl(vehiculoId));
    final data = response.data;
    if (data == null) return null;
    return InspeccionModel.fromJson(data as Map<String, dynamic>);
  }

  // =======================
  // AVERÍAS
  // =======================
  Future<List<AveriaListModel>> listarAverias() async {
    final response = await _dio.get('${ApiConfig.endpointAverias}/');
    return _list(response.data, AveriaListModel.fromJson);
  }

  Future<AveriaModel> obtenerAveria(int id) async {
    final response = await _dio.get(ApiConfig.getAveriaUrl(id));
    return AveriaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AveriaModel> crearAveria(CrearAveriaRequest request) async {
    final response = await _dio.post(
      ApiConfig.getAveriasUrl() + '/',
      data: request.toJson(),
    );
    return AveriaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AveriaModel> actualizarAveria(
    int id,
    ActualizarAveriaRequest request,
  ) async {
    final response = await _dio.put(
      ApiConfig.getAveriaUrl(id),
      data: request.toJson(),
    );
    return AveriaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AveriaListModel>> historialAveriasVehiculo(
    int vehiculoId,
  ) async {
    final response =
        await _dio.get(ApiConfig.getAveriasVehiculoUrl(vehiculoId));
    return _list(response.data, AveriaListModel.fromJson);
  }

  Future<void> eliminarAveria(int id) async {
    await _dio.delete(ApiConfig.getAveriaUrl(id));
  }

  // =======================
  // INCIDENTES
  // =======================
  Future<List<IncidenteListModel>> listarIncidentes() async {
    final response = await _dio.get('${ApiConfig.endpointIncidentes}/');
    return _list(response.data, IncidenteListModel.fromJson);
  }

  Future<IncidenteModel> obtenerIncidente(int id) async {
    final response = await _dio.get(ApiConfig.getIncidenteUrl(id));
    return IncidenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<IncidenteModel> crearIncidente(CrearIncidenteRequest request) async {
    final response = await _dio.post(
      ApiConfig.getIncidentesUrl() + '/',
      data: request.toJson(),
    );
    return IncidenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<IncidenteModel> actualizarIncidente(
    int id,
    ActualizarIncidenteRequest request,
  ) async {
    final response = await _dio.put(
      ApiConfig.getIncidenteUrl(id),
      data: request.toJson(),
    );
    return IncidenteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<IncidenteListModel>> historialIncidentesVehiculo(
    int vehiculoId,
  ) async {
    final response =
        await _dio.get(ApiConfig.getIncidentesVehiculoUrl(vehiculoId));
    return _list(response.data, IncidenteListModel.fromJson);
  }

  Future<void> eliminarIncidente(int id) async {
    await _dio.delete(ApiConfig.getIncidenteUrl(id));
  }

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    return (data as List<dynamic>)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

