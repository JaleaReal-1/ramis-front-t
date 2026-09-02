// lib/data/services/rq_service.dart

import 'package:dio/dio.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/data/models/rq_model.dart'; // Crearemos este modelo
import 'package:sistema_ocs/data/models/rq_item_model.dart'; // Y este

class RqService {
  final Dio _dio;

  RqService() : _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  // 💡 GET /rqs/
  Future<List<RQResponse>> listRqs() async {
    try {
      final response = await _dio.get('/rqs/');
      
      if (response.statusCode == 200) {
        // Mapear la lista de JSONs a List<RQResponse>
        return (response.data as List)
            .map((json) => RQResponse.fromJson(json))
            .toList();
      }
      throw Exception('Fallo al cargar RQs: ${response.statusCode}');
    } on DioException catch (e) {
      // Manejo de errores de red o servidor
      throw Exception('Error de conexión al listar RQs: ${e.message}');
    }
  }

  // 💡 DELETE /rqs/{rq_id}
  Future<void> deleteRq(int rqId) async {
    try {
      final response = await _dio.delete('/rqs/$rqId');
      
      if (response.statusCode != 200) {
        throw Exception('Fallo al eliminar el RQ: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error de conexión al eliminar RQ: ${e.message}');
    }
  }
}