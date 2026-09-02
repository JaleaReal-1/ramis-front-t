class MantenimientoModel {
  const MantenimientoModel({
    required this.id,
    required this.vehiculoId,
    required this.tipoMantenimiento,
    required this.descripcion,
    required this.estadoMantenimiento,
    required this.estadoEjecucion,
    required this.fechaRegistro,
    required this.kmRegistro,
    required this.horasRegistro,
    this.fechaEjecucion,
    this.kmEjecucion,
    this.horasEjecucion,
    required this.costo,
    this.averiaId,
    this.planMantenimientoId,
    this.trabajadorId,
    this.observacionesEjecucion,
    this.fechaBaja,
    this.usuarioBaja,
  });

  final int id;
  final int vehiculoId;
  final String tipoMantenimiento;
  final String descripcion;
  final String estadoMantenimiento;
  final String estadoEjecucion;
  final DateTime fechaRegistro;
  final double kmRegistro;
  final double horasRegistro;
  final DateTime? fechaEjecucion;
  final double? kmEjecucion;
  final double? horasEjecucion;
  final double costo;
  final int? averiaId;
  final int? planMantenimientoId;
  final int? trabajadorId;
  final String? observacionesEjecucion;
  final DateTime? fechaBaja;
  final int? usuarioBaja;

  factory MantenimientoModel.fromJson(Map<String, dynamic> json) {
    return MantenimientoModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      tipoMantenimiento: json['tipo_mantenimiento'] as String,
      descripcion: json['descripcion'] as String,
      estadoMantenimiento: json['estado_mantenimiento'] as String,
      estadoEjecucion: json['estado_ejecucion'] as String,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
      kmRegistro: (json['km_registro'] as num).toDouble(),
      horasRegistro: (json['horas_registro'] as num).toDouble(),
      fechaEjecucion: _date(json['fecha_ejecucion']),
      kmEjecucion: _num(json['km_ejecucion']),
      horasEjecucion: _num(json['horas_ejecucion']),
      costo: (json['costo'] as num).toDouble(),
      averiaId: json['averia_id'] as int?,
      planMantenimientoId: json['plan_mantenimiento_id'] as int?,
      trabajadorId: json['trabajador_id'] as int?,
      observacionesEjecucion: json['observaciones_ejecucion'] as String?,
      fechaBaja: _date(json['fecha_baja']),
      usuarioBaja: json['usuario_baja'] as int?,
    );
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v as String);
  static double? _num(dynamic v) =>
      v == null ? null : (v as num).toDouble();
}

class CrearMantenimientoCorreactivoRequest {
  const CrearMantenimientoCorreactivoRequest({
    required this.vehiculoId,
    required this.averiaId,
    required this.descripcion,
    this.costo = 0.0,
  });

  final int vehiculoId;
  final int averiaId;
  final String descripcion;
  final double costo;

  Map<String, dynamic> toJson() => {
        'vehiculo_id': vehiculoId,
        'averia_id': averiaId,
        'descripcion': descripcion,
        'costo': costo,
      };
}

class CrearMantenimientoPreventivoRequest {
  const CrearMantenimientoPreventivoRequest({
    required this.vehiculoId,
    required this.planMantenimientoId,
    required this.tipoControl,
    required this.descripcion,
    this.kmBase,
    this.fechaBase,
    this.horasBase,
  });

  final int vehiculoId;
  final int planMantenimientoId;
  final String tipoControl;
  final String descripcion;
  final double? kmBase;
  final DateTime? fechaBase;
  final double? horasBase;

  Map<String, dynamic> toJson() => {
        'vehiculo_id': vehiculoId,
        'plan_mantenimiento_id': planMantenimientoId,
        'tipo_control': tipoControl,
        'descripcion': descripcion,
        if (kmBase != null) 'km_base': kmBase,
        if (fechaBase != null) 'fecha_base': fechaBase!.toIso8601String(),
        if (horasBase != null) 'horas_base': horasBase,
      };
}

class EjecutarMantenimientoRequest {
  const EjecutarMantenimientoRequest({
    required this.trabajadorId,
    required this.kmEjecucion,
    this.horasEjecucion = 0.0,
    this.observacionesEjecucion,
  });

  final int trabajadorId;
  final double kmEjecucion;
  final double horasEjecucion;
  final String? observacionesEjecucion;

  Map<String, dynamic> toJson() => {
        'trabajador_id': trabajadorId,
        'km_ejecucion': kmEjecucion,
        'horas_ejecucion': horasEjecucion,
        if (observacionesEjecucion != null)
          'observaciones_ejecucion': observacionesEjecucion,
      };
}

class ActualizarMantenimientoRequest {
  const ActualizarMantenimientoRequest({
    this.descripcion,
    this.costo,
    this.observacionesEjecucion,
  });

  final String? descripcion;
  final double? costo;
  final String? observacionesEjecucion;

  Map<String, dynamic> toJson() => {
        if (descripcion != null) 'descripcion': descripcion,
        if (costo != null) 'costo': costo,
        if (observacionesEjecucion != null)
          'observaciones_ejecucion': observacionesEjecucion,
      };
}

/// Respuesta simplificada para listados.
class MantenimientoListModel {
  const MantenimientoListModel({
    required this.id,
    required this.vehiculoId,
    required this.tipoMantenimiento,
    required this.descripcion,
    required this.estadoMantenimiento,
    required this.estadoEjecucion,
    required this.fechaRegistro,
    required this.kmRegistro,
    required this.costo,
  });

  final int id;
  final int vehiculoId;
  final String tipoMantenimiento;
  final String descripcion;
  final String estadoMantenimiento;
  final String estadoEjecucion;
  final DateTime fechaRegistro;
  final double kmRegistro;
  final double costo;

  factory MantenimientoListModel.fromJson(Map<String, dynamic> json) {
    return MantenimientoListModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      tipoMantenimiento: json['tipo_mantenimiento'] as String,
      descripcion: json['descripcion'] as String,
      estadoMantenimiento: json['estado_mantenimiento'] as String,
      estadoEjecucion: json['estado_ejecucion'] as String,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
      kmRegistro: (json['km_registro'] as num).toDouble(),
      costo: (json['costo'] as num).toDouble(),
    );
  }
}

