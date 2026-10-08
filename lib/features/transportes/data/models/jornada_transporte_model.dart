import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class JornadaTransporteModel extends JornadaTransporte {
  const JornadaTransporteModel({
    required super.id,
    super.vehiculoId,
    required super.conductorId,
    required super.estado,
    super.fechaInicio,
    super.fechaFin,
    super.checklists,
    super.incidencias,
    super.accionTipo,
    super.ruta,
    super.nivelCombustible,
    super.checklistFlash,
    super.observaciones,
    super.kmInicial,
    super.kmFinal,
    super.horasEfectivas,
    super.alertaHoras,
    super.alertaKm,
    super.detallesGrua,
    super.detallesCombustible,
    super.detallesMantenimiento,
    super.detallesInspeccion,
    super.detallesCocada,
    super.detallesTorque,
    super.detallesTrabajosExternos,
  });

  factory JornadaTransporteModel.fromJson(Map<String, dynamic> json) {
    return JornadaTransporteModel(
      id: _int(json, 'id'),
      vehiculoId:
          json['vehiculo_id'] != null ? _int(json, 'vehiculo_id') : null,
      conductorId: _int(json, 'conductor_id'),
      estado: _str(json, 'estado'),
      fechaInicio: _date(json['fecha_inicio']),
      fechaFin: _date(json['fecha_fin']),
      checklists: _list(json['checklists'], ChecklistModel.fromJson),
      incidencias: _list(json['incidencias'], IncidenciaRutaModel.fromJson),
      accionTipo: json['accion_tipo'] as String?,
      ruta: json['ruta'] as String?,
      nivelCombustible: json['nivel_combustible'] != null
          ? _int(json, 'nivel_combustible')
          : null,
      checklistFlash: json['checklist_flash'] as Map<String, dynamic>?,
      observaciones: json['observaciones'] as String?,
      kmInicial: (json['km_inicial'] as num?)?.toDouble(),
      kmFinal: (json['km_final'] as num?)?.toDouble(),
      horasEfectivas: (json['horas_efectivas'] as num?)?.toDouble(),
      alertaHoras: json['alerta_horas'] as bool? ?? false,
      alertaKm: json['alerta_km'] as bool? ?? false,
      detallesGrua: json['detalles_grua'] as Map<String, dynamic>?,
      detallesCombustible:
          json['detalles_combustible'] as Map<String, dynamic>?,
      detallesMantenimiento:
          json['detalles_mantenimiento'] as Map<String, dynamic>?,
      detallesInspeccion: json['detalles_inspeccion'] as Map<String, dynamic>?,
      detallesCocada: json['detalles_cocada'] as Map<String, dynamic>?,
      detallesTorque: json['detalles_torque'] as Map<String, dynamic>?,
      detallesTrabajosExternos:
          json['detalles_trabajos_externos'] as Map<String, dynamic>?,
    );
  }
}

class ChecklistModel extends Checklist {
  const ChecklistModel({
    required super.id,
    required super.jornadaId,
    required super.tipo,
    required super.kilometraje,
    required super.nivelCombustible,
    required super.estadoGeneral,
    required super.conforme,
    super.observaciones,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    return ChecklistModel(
      id: _int(json, 'id'),
      jornadaId: _int(json, 'jornada_id'),
      tipo: _str(json, 'tipo'),
      kilometraje: _double(json, 'kilometraje'),
      nivelCombustible: _str(json, 'nivel_combustible'),
      estadoGeneral: _str(json, 'estado_general'),
      conforme: json['conforme'] as bool,
      observaciones: json['observaciones'] as String?,
    );
  }
}

class IncidenciaRutaModel extends IncidenciaRuta {
  const IncidenciaRutaModel({
    required super.id,
    required super.jornadaId,
    required super.tipo,
    required super.descripcion,
    required super.fecha,
  });

  factory IncidenciaRutaModel.fromJson(Map<String, dynamic> json) {
    return IncidenciaRutaModel(
      id: _int(json, 'id'),
      jornadaId: _int(json, 'jornada_id'),
      tipo: _str(json, 'tipo'),
      descripcion: _str(json, 'descripcion'),
      fecha: DateTime.parse(_str(json, 'fecha')),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────
int _int(Map<String, dynamic> j, String k) => (j[k] as num).toInt();
double _double(Map<String, dynamic> j, String k) => (j[k] as num).toDouble();
String _str(Map<String, dynamic> j, String k) => j[k] as String;
DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) fn) {
  if (v is! List<dynamic>) return <T>[];
  return v.map((e) => fn(e as Map<String, dynamic>)).toList();
}
