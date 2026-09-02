import 'package:dio/dio.dart';
import 'dart:io';
import 'package:sistema_ocs/core/config/api_config.dart';

class UrgentRQService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<List<dynamic>> buscarProductos(String query) async {
    try {
      final response = await _dio.get('/rq-residente/buscar-productos', queryParameters: {'q': query});
      return response.data;
    } catch (e) {
      throw Exception("Error al buscar productos");
    }
  }

  Future<void> enviarRequerimiento({
    required String servicio,
    required String solicitante,
    required String email,
    required String productosJson,
    required File firmaFile,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "servicio": servicio,
        "solicitante": solicitante,
        "user_email": email,
        "fecha": DateTime.now().toString().split(' ')[0],
        "productos_json": productosJson,
        "firma": await MultipartFile.fromFile(firmaFile.path, filename: "firma.png"),
      });

      final response = await _dio.post('/rq-residente/generar', data: formData);

      // Si el código es 200 o 201, lo damos por bueno sin importar el cuerpo de la respuesta
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Error del servidor: ${response.statusCode}");
      }
    } on DioException catch (e) {
      // Si el servidor responde 200 pero Dio falla al parsear el JSON, lo capturamos aquí
      if (e.response?.statusCode == 200 || e.response?.statusCode == 201) {
        return; // Es un éxito "falso" de Dio, pero real en el servidor
      }
      throw e.response?.data['detail'] ?? "Error de conexión: ${e.message}";
    }
  }
}