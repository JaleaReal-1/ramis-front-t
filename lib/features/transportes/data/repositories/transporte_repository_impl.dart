import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../transport_queue.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/features/transportes/data/models/jornada_transporte_model.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';

class TransporteRepositoryImpl {
  TransporteRepositoryImpl(this._dio) : queue = TransportQueue(_dio);
  final TransportQueue queue;

  final Dio _dio;
  Future<String> subirFoto(List<int> bytes, String nombre) async {
    if (bytes.length > 10 * 1024 * 1024) {
      throw const TransportFailure(message: 'Máximo 10 MB por archivo.');
    }
    try {
      final res = await _dio.post('${ApiConfig.baseUrl}/api/jornadas/fotos',
          data: FormData.fromMap(
              {'file': MultipartFile.fromBytes(bytes, filename: nombre)}));
      return _map(res.data)['url'] as String;
    } on DioException catch (e) {
      if (!_offline(e)) throw _failureFromDio(e);
      return queue.keepImage(bytes, nombre);
    }
  }

  // ── Jornadas ────────────────────────────────────────────

  Future<JornadaTransporte> asignar(AsignarJornadaRequest request) async {
    final res = await _request(
      () => _dio.post(ApiConfig.getAsignarJornadaUrl(), data: request.toJson()),
    );
    return JornadaTransporteModel.fromJson(_map(res.data));
  }

  Future<JornadaTransporte> registrarAccion(
      RegistroAccionRequest request) async {
    if (request.accionTipo == 'Reporte de Incidencias u Observaciones' &&
        request.jornadaPadreId != null) {
      await registrarIncidencia(
          request.jornadaPadreId!,
          IncidenciaRutaRequest(
              tipo: 'falla',
              descripcion: request.observaciones,
              severidad: request.severidad,
              fotoIncidencia: request.fotoObservacion,
              fotos: request.fotosObservacion));
      return obtenerJornada(request.jornadaPadreId!);
    }
    final body = request.toJson()..['solicitud_id'] = const Uuid().v4();
    final path =
        '${ApiConfig.baseUrl}${ApiConfig.endpointJornadas}/registro-accion';
    if (request.accionTipo == 'Reporte de Incidencias u Observaciones' &&
        body.toString().contains('local://')) {
      await queue.add(path, body);
      throw const TransportQueued();
    }
    try {
      final res = await _request(
        () => _dio.post(
            '${ApiConfig.baseUrl}${ApiConfig.endpointJornadas}/registro-accion',
            data: body),
      );
      return JornadaTransporteModel.fromJson(_map(res.data));
    } on TransportFailure catch (e) {
      if (request.accionTipo != 'Reporte de Incidencias u Observaciones' ||
          e.statusCode != null) {
        rethrow;
      }
      await queue.add(path, body);
      throw const TransportQueued();
    }
  }

  Future<double> obtenerKilometrajeVehiculo(int vehiculoId) async {
    final res = await _request(
      () => _dio
          .get('${ApiConfig.baseUrl}/api/vehiculos/$vehiculoId/kilometraje'),
    );
    final data = _map(res.data);
    return (data['kilometraje_actual'] as num?)?.toDouble() ?? 0.0;
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
      () => _dio
          .get('${ApiConfig.baseUrl}${ApiConfig.endpointJornadas}/$jornadaId'),
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
    final body = request.toJson()..['solicitud_id'] = const Uuid().v4();
    final path = ApiConfig.getIncidenciasJornadaUrl(jornadaId);
    if (body.toString().contains('local://')) {
      await queue.add(path, body);
      throw const TransportQueued();
    }
    late Response<dynamic> res;
    try {
      res = await _dio.post(path, data: body);
    } on DioException catch (e) {
      if (!_offline(e)) throw _failureFromDio(e);
      await queue.add(path, body);
      throw const TransportQueued();
    }
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

  Future<void> actualizarDatosVehiculo(
      int id, String tipo, double? capacidad) async {
    await _request(() => _dio.put(
            '${ApiConfig.baseUrl}${ApiConfig.endpointVehiculos}/$id',
            data: {
              'tipo': tipo,
              if (capacidad != null) 'capacidad_tanque_galones': capacidad
            }));
  }

  Future<Map<String, dynamic>> obtenerVehiculo(int vehiculoId) async {
    final res = await _request(
      () => _dio.get(
          '${ApiConfig.baseUrl}${ApiConfig.endpointVehiculos}/$vehiculoId'),
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
  Future<List<Map<String, dynamic>>> listarConductores() async =>
      (await getV3('/api/transportes/conductores') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<List<Map<String, dynamic>>> documentos(String entidad, int id) async {
    final rows =
        await getV3('/api/transportes/documentos/$entidad/$id/vigencias')
            as List;
    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> historialDocumentos(
          String entidad, int id) async =>
      (await getV3('/api/transportes/documentos/$entidad/$id?historial=true')
              as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  /// Retorna false cuando el envío queda guardado para sincronización.
  Future<bool> subirDocumento(String entidad, int id,
      Map<String, dynamic> fields, List<int> bytes, String name) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const TransportFailure(
          message: 'Adjunte un archivo de hasta 10 MB.');
    }
    final path = '/api/transportes/documentos/$entidad/$id';
    final data = {...fields, 'solicitud_id': const Uuid().v4()};
    try {
      await _dio.post(path,
          data: FormData.fromMap({
            ...data,
            'file': MultipartFile.fromBytes(bytes, filename: name)
          }));
      return true;
    } on DioException catch (error) {
      if (!_offline(error) && (error.response?.statusCode ?? 0) < 500) {
        throw _failureFromDio(error);
      }
      await queue.addMultipart(path, data, bytes, name);
      return false;
    }
  }

  Future<void> revisarDocumento(int id, String estado, String motivo) async {
    await postV3('/api/transportes/documentos/$id/revisar',
        {'estado': estado, 'motivo': motivo});
  }

  Future<void> configurarAcceso(int id, String email, String password) async {
    await _request(() => _dio.put('/api/transportes/conductores/$id/acceso',
        data: {'email': email, 'password': password}));
  }

  Future<Map<String, dynamic>> altaConductor(
          String dni, String nombre, String apellidos) async =>
      _map(await postV3('/api/transportes/conductores/alta-rapida',
          {'dni': dni, 'nombre': nombre, 'apellidos': apellidos}));

  Future<Map<String, dynamic>> altaVehiculo(Map<String, dynamic> data) async =>
      _map(await postV3('/api/transportes/vehiculos', data));

  Future<List<int>> descargarArchivo(String path) async {
    final uri = Uri.parse(path);
    final base = Uri.parse(ApiConfig.baseUrl);
    if (uri.hasAuthority && uri.origin != base.origin) {
      throw const TransportFailure(
          message: 'Archivo fuera del servidor autorizado.');
    }
    final response = await _request(() =>
        _dio.get(path, options: Options(responseType: ResponseType.bytes)));
    return List<int>.from(response.data as List);
  }

  Future<dynamic> getV3(String path) async =>
      (await _request(() => _dio.get(path))).data;
  Future<dynamic> postV3(String path, Map<String, dynamic> body) async =>
      (await _request(() => _dio.post(path, data: body))).data;
  Future<void> cerrarSubaccion(int id, Map<String, dynamic> body) async {
    await postV3('/api/jornadas/$id/cerrar', body);
  }

  Future<void> cancelarSubaccion(int id, String motivo) async {
    await postV3('/api/jornadas/$id/cancelar', {'motivo': motivo});
  }

  Future<List<int>> reportePdf(
      int id, String estado, String? desde, String? hasta) async {
    final res = await _request(
        () => _dio.get('/api/transportes/vehiculos/$id/reporte-pdf',
            queryParameters: {
              'estado': estado,
              if (desde != null) 'desde': desde,
              if (hasta != null) 'hasta': hasta
            },
            options: Options(responseType: ResponseType.bytes)));
    return List<int>.from(res.data as List);
  }

  bool _offline(DioException e) =>
      e.response == null && e.type != DioExceptionType.cancel;

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      if (response.requestOptions.method == 'GET' &&
          response.requestOptions.responseType != ResponseType.bytes) {
        try {
          await queue.cache(
              response.requestOptions.uri.toString(), response.data);
        } catch (_) {}
      }
      return response;
    } on DioException catch (error) {
      if (_offline(error) && error.requestOptions.method == 'GET') {
        try {
          final previous =
              await queue.cached(error.requestOptions.uri.toString());
          if (previous != null) {
            return Response(
                data: previous,
                requestOptions: error.requestOptions,
                statusCode: 200);
          }
        } catch (_) {}
      }
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

class TransportQueued implements Exception {
  const TransportQueued();
  @override
  String toString() =>
      'Reporte guardado en el dispositivo. Se enviará automáticamente al recuperar conexión.';
}
