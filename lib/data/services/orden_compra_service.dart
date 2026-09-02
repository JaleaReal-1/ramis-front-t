import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/features/ordenes_compra/models/orden_compra_request.dart';

class OrdenCompraService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  // 1. CAMINO A: Enviar JSON Completo
  Future<int> crearOrden(OrdenCompraRequest request) async {
    try {
      final response = await _dio.post(
        '/ordenes/',
        data: request.toJson(), // Aquí va el JSON completo que armamos localmente
      );
      // El backend debe responder con {"orden_id": 123}
      return response.data['orden_id']; 
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error al crear la orden');
    }
  }

  // 2. CAMINO B: Subir Comprobante Físico (Uno por uno)
  Future<void> subirComprobante({
    required int ordenId,
    required File file,
    required String tipoDocumento,
    String? numero,
    String? fecha,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path, 
          filename: file.path.split('/').last
        ),
        'tipo_documento': tipoDocumento,
        if (numero != null) 'numero_comprobante': numero,
        if (fecha != null) 'fecha': fecha,
        'es_factura': tipoDocumento != 'GUIA_REMISION',
      });

      await _dio.post(
        '/ordenes/$ordenId/comprobantes/upload',
        data: formData,
      );
    } on DioException catch (e) {
      throw Exception('Error en upload: ${e.response?.data['detail']}');
    }
  }

  // 3. Otros métodos de gestión en servidor
  Future<void> eliminarOrdenServidor(int ordenId) async {
    try {
      await _dio.delete('/ordenes/$ordenId');
    } on DioException {
      throw Exception('No se pudo eliminar en servidor');
    }
  }
}