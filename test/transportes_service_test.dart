import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/core/config/api_config.dart';

void main() {
  group('ApiConfig - URL base centralizada', () {
    test('toda la configuracion usa la misma base url', () {
      final base = ApiConfig.baseUrl;
      expect(
        ApiConfig.getVehiculosUrl().startsWith(base),
        true,
        reason: 'Todos los endpoints deben usar la misma URL base',
      );
      expect(
        ApiConfig.getInspeccionVehiculoHistorialUrl(1).startsWith(base),
        true,
      );
      expect(
        ApiConfig.getAveriasVehiculoUrl(1).startsWith(base),
        true,
      );
      expect(
        ApiConfig.getIncidentesVehiculoUrl(1).startsWith(base),
        true,
      );
      expect(
        ApiConfig.getMantenimientosVehiculoUrl(1).startsWith(base),
        true,
      );
      expect(
        ApiConfig.getChecklistItemsUrl().startsWith(base),
        true,
      );
    });

    test('endpoints de mantenimiento usan rutas correctas', () {
      final base = ApiConfig.baseUrl;
      expect(
        ApiConfig.getCrearMantenimientoCorractivoUrl(),
        '$base/api/mantenimientos/correctivo',
      );
      expect(
        ApiConfig.getEjecutarMantenimientoUrl(5),
        '$base/api/mantenimientos/5/ejecutar',
      );
      expect(
        ApiConfig.getMantenimientosVencidosUrl(),
        '$base/api/mantenimientos/reportes/vencidos',
      );
    });

    test('endpoints de inspecciones y checklist', () {
      final base = ApiConfig.baseUrl;
      expect(
        ApiConfig.getChecklistItemsUrl(),
        '$base/api/inspecciones/checklist-items',
      );
      expect(
        ApiConfig.getInspeccionVehiculoHistorialUrl(3),
        '$base/api/inspecciones/vehiculo/3/historial',
      );
      expect(
        ApiConfig.getInspeccionVehiculoUltimaUrl(3),
        '$base/api/inspecciones/vehiculo/3/ultima',
      );
    });

    test('endpoints de averias e incidentes por vehiculo', () {
      final base = ApiConfig.baseUrl;
      expect(
        ApiConfig.getAveriasVehiculoUrl(2),
        '$base/api/averias/vehiculo/2/historial',
      );
      expect(
        ApiConfig.getIncidentesVehiculoUrl(2),
        '$base/api/incidentes/vehiculo/2/historial',
      );
    });
  });
}
