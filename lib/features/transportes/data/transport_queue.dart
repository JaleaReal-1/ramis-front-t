import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Cola persistente aislada por servidor y sujeto autenticado. Nunca guarda JWT.
class TransportQueue {
  TransportQueue(this.dio, {FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();
  final Dio dio;
  final FlutterSecureStorage storage;
  Timer? _timer;
  bool _running = false;
  Future<void> _serial = Future.value();
  String? lastError;

  Future<String> _key() async {
    final token = await storage.read(key: 'jwt_token');
    if (token == null) {
      throw StateError('Inicie sesión para guardar pendientes.');
    }
    final payload = jsonDecode(utf8.decode(
        base64Url.decode(base64Url.normalize(token.split('.')[1])))) as Map;
    return 'transport_queue:${dio.options.baseUrl}:${payload['sub']}';
  }

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _serial.then((_) => action());
    _serial = result.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return result;
  }

  Future<Map<String, dynamic>> _load(String key) async {
    final raw = await storage.read(key: key);
    return raw == null
        ? {'images': <String, dynamic>{}, 'jobs': <dynamic>[]}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<String> keepImage(List<int> bytes, String name) => _locked(() async {
        final key = await _key();
        final data = await _load(key);
        final id = 'local://${const Uuid().v4()}';
        (data['images'] as Map)[id] = {
          'bytes': base64Encode(bytes),
          'name': name
        };
        await storage.write(key: key, value: jsonEncode(data));
        return id;
      });

  Future<void> add(String path, Map<String, dynamic> body) => _locked(() async {
        final key = await _key();
        final data = await _load(key);
        (data['jobs'] as List).add({'path': path, 'body': body});
        await storage.write(key: key, value: jsonEncode(data));
      });

  Future<void> addMultipart(String path, Map<String, dynamic> fields,
          List<int> bytes, String name) =>
      _locked(() async {
        final key = await _key();
        final data = await _load(key);
        (data['jobs'] as List).add({
          'path': path,
          'body': fields,
          'multipart': {'bytes': base64Encode(bytes), 'name': name}
        });
        await storage.write(key: key, value: jsonEncode(data));
      });

  Future<int> pending() async =>
      ((await _load(await _key()))['jobs'] as List).length;

  Future<int> pendingDocuments(String entidad, int id) async {
    final jobs = (await _load(await _key()))['jobs'] as List;
    return jobs
        .where(
            (job) => job['path'] == '/api/transportes/documentos/$entidad/$id')
        .length;
  }

  Future<void> cache(String path, dynamic value) async {
    final key = '${await _key()}:cache:$path';
    await storage.write(key: key, value: jsonEncode(value));
  }

  Future<dynamic> cached(String path) async {
    final raw = await storage.read(key: '${await _key()}:cache:$path');
    return raw == null ? null : jsonDecode(raw);
  }

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> flush() async {
    if (_running) return;
    _running = true;
    try {
      await _locked(() async {
        final key = await _key();
        final data = await _load(key);
        final jobs = data['jobs'] as List;
        final images = data['images'] as Map;
        while (jobs.isNotEmpty) {
          final job = jobs.first as Map;
          final references = <String>{};
          void collect(dynamic value) {
            if (value is String && value.startsWith('local://')) {
              references.add(value);
            }
            if (value is Map) {
              for (final v in value.values) {
                collect(v);
              }
            }
            if (value is List) {
              for (final v in value) {
                collect(v);
              }
            }
          }

          collect(job['body']);
          final urls = <String, String>{};
          for (final id in references) {
            final image = images[id] as Map?;
            if (image == null) throw StateError('Falta una evidencia local.');
            if (image['url'] == null) {
              final response = await dio.post('/api/jornadas/fotos',
                  data: FormData.fromMap({
                    'file': MultipartFile.fromBytes(
                        base64Decode(image['bytes'] as String),
                        filename: image['name'] as String)
                  }));
              image['url'] = response.data['url'];
              await storage.write(key: key, value: jsonEncode(data));
            }
            urls[id] = image['url'] as String;
          }
          dynamic replace(dynamic value) {
            if (value is String) return urls[value] ?? value;
            if (value is Map) {
              return value.map((k, v) => MapEntry(k, replace(v)));
            }
            if (value is List) return value.map(replace).toList();
            return value;
          }

          // Si cambió la sesión, conservar el trabajo para su propietario.
          if (await _key() != key) return;
          final attachment = job['multipart'] as Map?;
          final body = attachment == null
              ? replace(job['body'])
              : FormData.fromMap({
                  ...Map<String, dynamic>.from(job['body'] as Map),
                  'file': MultipartFile.fromBytes(
                      base64Decode(attachment['bytes'] as String),
                      filename: attachment['name'] as String),
                });
          await dio.post(job['path'] as String, data: body);
          jobs.removeAt(0);
          for (final id in references) {
            images.remove(id);
          }
          await storage.write(key: key, value: jsonEncode(data));
        }
        lastError = null;
      });
    } catch (error) {
      lastError = error.toString();
    } finally {
      _running = false;
    }
  }
}
