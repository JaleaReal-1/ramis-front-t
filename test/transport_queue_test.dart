import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/features/transportes/data/transport_queue.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';

class _Adapter implements HttpClientAdapter {
  final bodies = <Map>[];
  bool fail = false;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (fail) {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    }
    if (options.path.endsWith('/fotos')) {
      return ResponseBody.fromString(
          '{"url":"/uploads/transportes/abc.jpg"}', 201,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.data is FormData) {
      final form = options.data as FormData;
      bodies.add(
          {...Map.fromEntries(form.fields), '_file_count': form.files.length});
    } else {
      bodies.add(Map.from(options.data as Map));
    }
    return ResponseBody.fromString('{}', 201, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

String token(String user) => 'header.${base64Url.encode(utf8.encode(jsonEncode({
          'sub': user
        })))}.signature';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('La cola persiste evidencia y reintenta sin perder el identificador',
      () async {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': token('conductor1')});
    final adapter = _Adapter()..fail = true;
    final dio = Dio(BaseOptions(baseUrl: 'https://test.ramis.pe'))
      ..httpClientAdapter = adapter;
    final queue = TransportQueue(dio);
    final foto = await queue.keepImage([1, 2, 3], 'foto.jpg');
    await queue.add('/api/jornadas/1/incidencias', {
      'solicitud_id': 'request-stable-001',
      'fotos': [foto]
    });
    await queue.flush();
    expect(await queue.pending(), 1);
    adapter.fail = false;
    final reiniciada = TransportQueue(dio);
    await reiniciada.flush();
    expect(await reiniciada.pending(), 0);
    expect(adapter.bodies.single['solicitud_id'], 'request-stable-001');
    expect(adapter.bodies.single['fotos'], ['/uploads/transportes/abc.jpg']);
  });
  test('Otro conductor no envía los pendientes de la cuenta anterior',
      () async {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': token('conductor1')});
    const storage = FlutterSecureStorage();
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.ramis.pe'))
      ..httpClientAdapter = adapter;
    final queue = TransportQueue(dio);
    await queue.add(
        '/api/jornadas/1/incidencias', {'solicitud_id': 'request-owner-001'});
    await storage.write(key: 'jwt_token', value: token('conductor2'));
    await queue.flush();
    expect(adapter.bodies, isEmpty);
    await storage.write(key: 'jwt_token', value: token('conductor1'));
    expect(await queue.pending(), 1);
  });
  test(
      'Documento multipart sobrevive a un reinicio y conserva categoría y solicitud',
      () async {
    FlutterSecureStorage.setMockInitialValues(
        {'jwt_token': token('conductor1')});
    final adapter = _Adapter()..fail = true;
    final dio = Dio(BaseOptions(baseUrl: 'https://test.ramis.pe'))
      ..httpClientAdapter = adapter;
    final repo = TransporteRepositoryImpl(dio);
    final enviado = await repo.subirDocumento(
        'conductor',
        7,
        {
          'tipo': 'licencia',
          'fecha_vencimiento': '2027-01-01',
          'licencia_categoria': 'A-IIb'
        },
        [1, 2, 3],
        'licencia.png');
    expect(enviado, isFalse);
    expect(await repo.queue.pendingDocuments('conductor', 7), 1);
    adapter.fail = false;
    final reiniciada = TransportQueue(dio);
    await reiniciada.flush();
    expect(await reiniciada.pendingDocuments('conductor', 7), 0);
    expect(adapter.bodies.single['licencia_categoria'], 'A-IIb');
    expect(adapter.bodies.single['solicitud_id'], isNotEmpty);
    expect(adapter.bodies.single['_file_count'], 1);
  });
}
