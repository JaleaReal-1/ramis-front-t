import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/features/transportes/models/averia_model.dart';
import 'package:sistema_ocs/features/transportes/models/incidente_model.dart';
import 'package:sistema_ocs/features/transportes/models/inspeccion_model.dart';
import 'package:sistema_ocs/features/transportes/models/mantenimiento_model.dart';
import 'package:sistema_ocs/features/transportes/models/vehiculo_model.dart';

void main() {
  group('VehiculoModel', () {
    test('parsea correctamente incluyendo kilometraje_actual', () {
      final json = {
        'id': 1,
        'placa': 'ABC-123',
        'marca': 'Toyota',
        'modelo': 'Hilux',
        'capacidad_carga': 1.5,
        'estado': 'disponible',
        'kilometraje_actual': 15000.0,
        'fecha_baja': null,
        'usuario_baja': null,
      };
      final v = VehiculoModel.fromJson(json);
      expect(v.id, 1);
      expect(v.placa, 'ABC-123');
      expect(v.kilometrajeActual, 15000.0);
      expect(v.estado, 'disponible');
    });

    test('kilometraje_actual ausente se convierte en null', () {
      final json = {
        'id': 2,
        'placa': 'XYZ-999',
        'marca': 'Nissan',
        'modelo': 'Navara',
        'capacidad_carga': 1.0,
        'estado': 'disponible',
      };
      final v = VehiculoModel.fromJson(json);
      expect(v.kilometrajeActual, isNull);
    });
  });

  group('MantenimientoModel', () {
    test('parsea respuesta detallada del backend', () {
      final json = {
        'id': 10,
        'vehiculo_id': 3,
        'tipo_mantenimiento': 'correctivo',
        'descripcion': 'Frenos',
        'estado_mantenimiento': 'NORMAL',
        'estado_ejecucion': 'completado',
        'fecha_registro': '2026-01-01T10:00:00',
        'km_registro': 15000.0,
        'horas_registro': 0.0,
        'fecha_ejecucion': '2026-01-02T10:00:00',
        'km_ejecucion': 15100.0,
        'horas_ejecucion': 0.0,
        'costo': 250.0,
        'averia_id': 5,
        'plan_mantenimiento_id': null,
        'trabajador_id': 2,
        'observaciones_ejecucion': 'Ok',
        'fecha_baja': null,
        'usuario_baja': null,
      };
      final m = MantenimientoModel.fromJson(json);
      expect(m.id, 10);
      expect(m.tipoMantenimiento, 'correctivo');
      expect(m.estadoMantenimiento, 'NORMAL');
      expect(m.estadoEjecucion, 'completado');
      expect(m.kmEjecucion, 15100.0);
      expect(m.averiaId, 5);
      expect(m.trabajadorId, 2);
    });

    test('parsea lista simplificada', () {
      final json = {
        'id': 11,
        'vehiculo_id': 4,
        'tipo_mantenimiento': 'preventivo',
        'descripcion': 'Cambio aceite',
        'estado_mantenimiento': 'PROXIMO',
        'estado_ejecucion': 'pendiente',
        'fecha_registro': '2026-01-01T10:00:00',
        'km_registro': 20000.0,
        'costo': 120.0,
      };
      final m = MantenimientoListModel.fromJson(json);
      expect(m.tipoMantenimiento, 'preventivo');
      expect(m.estadoEjecucion, 'pendiente');
      expect(m.costo, 120.0);
    });

    test('EjecutarMantenimientoRequest genera el JSON esperado', () {
      final req = EjecutarMantenimientoRequest(
        trabajadorId: 7,
        kmEjecucion: 16000.0,
        horasEjecucion: 2.0,
        observacionesEjecucion: 'Listo',
      );
      expect(req.toJson()['trabajador_id'], 7);
      expect(req.toJson()['km_ejecucion'], 16000.0);
      expect(req.toJson()['horas_ejecucion'], 2.0);
      expect(req.toJson()['observaciones_ejecucion'], 'Listo');
    });
  });

  group('InspeccionModel', () {
    test('parsea inspeccion con detalles', () {
      final json = {
        'id': 20,
        'vehiculo_id': 1,
        'trabajador_id': 5,
        'tipo': 'salida',
        'fecha': '2026-01-01T08:00:00',
        'kilometraje': 14000.0,
        'combustible': '3/4',
        'observaciones': 'Sin novedad',
        'ruta_id': 6,
        'firma': null,
        'resultado': 'aprobada',
        'detalles': [
          {
            'id': 1,
            'inspeccion_id': 20,
            'checklist_item_id': 2,
            'resultado_item': 'conforme',
            'checklist_item': {
              'id': 2,
              'nombre': 'Llantas',
              'categoria': 'Seguridad',
              'criticidad': 'alta',
              'orden': 1,
              'activo': true,
            },
          },
        ],
      };
      final i = InspeccionModel.fromJson(json);
      expect(i.tipo, 'salida');
      expect(i.resultado, 'aprobada');
      expect(i.detalles, hasLength(1));
      expect(i.detalles!.first.checklistItem!.nombre, 'Llantas');
    });

    test('CrearInspeccionRequest incluye detalles en JSON', () {
      final req = CrearInspeccionRequest(
        vehiculoId: 1,
        trabajadorId: 5,
        tipo: 'llegada',
        kilometraje: 14500.0,
        combustible: '1/2',
        detalles: [
          InspeccionDetalleCreate(
            checklistItemId: 2,
            resultadoItem: 'conforme',
          ),
        ],
        rutaId: 6,
      );
      final json = req.toJson();
      expect(json['tipo'], 'llegada');
      expect(json['detalles'], hasLength(1));
      expect((json['detalles'] as List).first['checklist_item_id'], 2);
      expect(json['ruta_id'], 6);
    });
  });

  group('AveriaModel', () {
    test('parsea averia completa', () {
      final json = {
        'id': 30,
        'vehiculo_id': 1,
        'categoria': 'Motor',
        'componente': 'Bomba',
        'descripcion': 'Falla de presion',
        'criticidad': 'critica',
        'origen': 'operacion',
        'fecha_reporte': '2026-01-01T09:00:00',
        'estado': 'reportada',
        'ruta_id': null,
        'trabajador_id': 5,
        'inspeccion_id': null,
        'kilometraje': 14000.0,
        'fecha_baja': null,
        'usuario_baja': null,
      };
      final a = AveriaModel.fromJson(json);
      expect(a.criticidad, 'critica');
      expect(a.estado, 'reportada');
      expect(a.kilometraje, 14000.0);
    });

    test('CrearAveriaRequest genera JSON', () {
      final req = CrearAveriaRequest(
        vehiculoId: 1,
        categoria: 'Electrico',
        componente: 'Alternador',
        descripcion: 'No carga',
        criticidad: 'alta',
        origen: 'inspeccion_llegada',
      );
      expect(req.toJson()['origen'], 'inspeccion_llegada');
      expect(req.toJson()['criticidad'], 'alta');
    });
  });

  group('IncidenteModel', () {
    test('parsea incidente', () {
      final json = {
        'id': 40,
        'vehiculo_id': 1,
        'trabajador_id': 5,
        'tipo': 'colision',
        'ubicacion': 'Km 12',
        'descripcion': 'Golpe leve',
        'hay_danos': true,
        'hay_personas_afectadas': false,
        'fecha': '2026-01-01T11:00:00',
        'estado': 'reportado',
        'ruta_id': 6,
        'fecha_baja': null,
        'usuario_baja': null,
      };
      final inc = IncidenteModel.fromJson(json);
      expect(inc.tipo, 'colision');
      expect(inc.hayDanos, true);
      expect(inc.hayPersonasAfectadas, false);
    });

    test('CrearIncidenteRequest genera JSON con generar_averia', () {
      final req = CrearIncidenteRequest(
        vehiculoId: 1,
        trabajadorId: 5,
        tipo: 'choque',
        ubicacion: 'Km 5',
        descripcion: 'Impacto frontal',
        hayPersonasAfectadas: true,
        generarAveria: true,
        averiaCriticidad: 'critica',
      );
      expect(req.toJson()['generar_averia'], true);
      expect(req.toJson()['hay_personas_afectadas'], true);
      expect(req.toJson()['averia_criticidad'], 'critica');
    });
  });
}

