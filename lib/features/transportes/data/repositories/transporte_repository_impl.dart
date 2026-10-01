import 'package:dio/dio.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/features/transportes/data/models/jornada_transporte_model.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';

class TransporteRepositoryImpl {
  TransporteRepositoryImpl(this._dio);

  final Dio _dio;

  // ── Jornadas ────────────────────────────────────────────

  Future<JornadaTransporte> asignar(AsignarJornadaRequest request) async {
    final res = await _request(
      () => _dio.post(ApiConfig.getAsignarJornadaUrl(), data: request.toJson()),
    );
    return JornadaTransporteModel.fromJson(_map(res.data));
  }

  Future<JornadaTransporte> registrarAccion(RegistroAccionRequest request) async {
    final res = await _request(
      () => _dio.post('${ApiConfig.baseUrl}${ApiConfig.endpointJornadas}/registro-accion', data: request.toJson()),
    );
    return JornadaTransporteModel.fromJson(_map(res.data));
  }

  Future<List<JornadaTransporte>> listarJornadas() async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}${ApiConfig.endpointJornadas}'),
    );
    return (res.data as List<dynamic>)
        .map((e) => JornadaTransporteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<JornadaTransporte> obtenerJornada(int jornadaId) async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}${ApiConfig.endpointJornadas}/$jornadaId'),
    );
    return JornadaTransporteModel.fromJson(_map(res.data));
  }

  Future<JornadaTransporte> registrarChecklistInicial(
    int jornadaId,
    ChecklistRequest request,
  ) async {
    final res = await _request(
      () => _dio.post(
        ApiConfig.getChecklistInicialUrl(jornadaId),
        data: request.toJson(),
      ),
    );
    return JornadaTransporteModel.fromJson(_map(res.data));
  }

  Future<JornadaTransporte> registrarChecklistFinal(
    int jornadaId,
    ChecklistRequest request,
  ) async {
    final res = await _request(
      () => _dio.post(
        ApiConfig.getChecklistFinalUrl(jornadaId),
        data: request.toJson(),
      ),
    );
    return JornadaTransporteModel.fromJson(_map(res.data));
  }

  Future<IncidenciaRuta> registrarIncidencia(
    int jornadaId,
    IncidenciaRutaRequest request,
  ) async {
    final res = await _request(
      () => _dio.post(
        ApiConfig.getIncidenciasJornadaUrl(jornadaId),
        data: request.toJson(),
      ),
    );
    return IncidenciaRutaModel.fromJson(_map(res.data));
  }

  // ── Vehículos (usado por pantalla de asignación) ─────────

  Future<List<Map<String, dynamic>>> listarVehiculos() async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}${ApiConfig.endpointVehiculos}'),
    );
    return (res.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>> obtenerVehiculo(int vehiculoId) async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}${ApiConfig.endpointVehiculos}/$vehiculoId'),
    );
    return _map(res.data);
  }

  Future<List<Map<String, dynamic>>> listarMantenimientos() async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}${ApiConfig.endpointMantenimientos}'),
    );
    return (res.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listarAverias() async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}${ApiConfig.endpointAverias}'),
    );
    return (res.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listarIncidentes() async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}${ApiConfig.endpointIncidentes}'),
    );
    return (res.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listarRutas() async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}${ApiConfig.endpointRutas}'),
    );
    return (res.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ── Trabajadores (usado por pantalla de asignación) ──────

  Future<List<Map<String, dynamic>>> listarTrabajadores() async {
    final res = await _request(
      () => _dio.get('${ApiConfig.baseUrl}/auth/trabajadores'),
    );
    return (res.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ── Helpers ─────────────────────────────────────────────

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw _failureFromDio(error);
    } on FormatException catch (e) {
      throw TransportFailure(message: 'Respuesta inválida: $e');
    } on TypeError catch (e) {
      throw TransportFailure(message: 'Respuesta inválida: $e');
    }
  }

  TransportFailure _failureFromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final detail = data is Map<String, dynamic> ? data['detail'] : null;

    final errors = <String>[];
    if (detail is String) {
      errors.add(detail);
    } else if (detail is List<dynamic>) {
      errors.addAll(detail.map((e) => e.toString()));
    }

    final message = errors.isNotEmpty
        ? errors.join(', ')
        : error.message ?? 'No se pudo completar la operación.';

    return TransportFailure(
      message: message,
      statusCode: statusCode,
      validationErrors: errors,
    );
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const TransportFailure(
      message: 'Respuesta del servidor con formato inválido.',
    );
  }
}
