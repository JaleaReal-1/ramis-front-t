class AveriaModel {
  const AveriaModel({
    required this.id,
    required this.vehiculoId,
    required this.categoria,
    required this.componente,
    required this.descripcion,
    required this.criticidad,
    required this.origen,
    required this.fechaReporte,
    required this.estado,
    this.rutaId,
    this.trabajadorId,
    this.inspeccionId,
    this.kilometraje,
    this.fechaBaja,
    this.usuarioBaja,
  });

  final int id;
  final int vehiculoId;
  final String categoria;
  final String componente;
  final String descripcion;
  final String criticidad;
  final String origen;
  final DateTime fechaReporte;
  final String estado;
  final int? rutaId;
  final int? trabajadorId;
  final int? inspeccionId;
  final double? kilometraje;
  final DateTime? fechaBaja;
  final int? usuarioBaja;

  factory AveriaModel.fromJson(Map<String, dynamic> json) {
    return AveriaModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      categoria: json['categoria'] as String,
      componente: json['componente'] as String,
      descripcion: json['descripcion'] as String,
      criticidad: json['criticidad'] as String,
      origen: json['origen'] as String,
      fechaReporte: DateTime.parse(json['fecha_reporte'] as String),
      estado: json['estado'] as String,
      rutaId: json['ruta_id'] as int?,
      trabajadorId: json['trabajador_id'] as int?,
      inspeccionId: json['inspeccion_id'] as int?,
      kilometraje: _num(json['kilometraje']),
      fechaBaja: _date(json['fecha_baja']),
      usuarioBaja: json['usuario_baja'] as int?,
    );
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v as String);
  static double? _num(dynamic v) =>
      v == null ? null : (v as num).toDouble();
}

/// Respuesta simplificada para listados
class AveriaListModel {
  const AveriaListModel({
    required this.id,
    required this.vehiculoId,
    required this.categoria,
    required this.componente,
    required this.criticidad,
    required this.estado,
    required this.fechaReporte,
  });

  final int id;
  final int vehiculoId;
  final String categoria;
  final String componente;
  final String criticidad;
  final String estado;
  final DateTime fechaReporte;

  factory AveriaListModel.fromJson(Map<String, dynamic> json) {
    return AveriaListModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      categoria: json['categoria'] as String,
      componente: json['componente'] as String,
      criticidad: json['criticidad'] as String,
      estado: json['estado'] as String,
      fechaReporte: DateTime.parse(json['fecha_reporte'] as String),
    );
  }
}

class CrearAveriaRequest {
  const CrearAveriaRequest({
    required this.vehiculoId,
    required this.categoria,
    required this.componente,
    required this.descripcion,
    required this.criticidad,
    required this.origen,
    this.rutaId,
    this.trabajadorId,
    this.inspeccionId,
  });

  final int vehiculoId;
  final String categoria;
  final String componente;
  final String descripcion;
  final String criticidad;
  final String origen;
  final int? rutaId;
  final int? trabajadorId;
  final int? inspeccionId;

  Map<String, dynamic> toJson() => {
        'vehiculo_id': vehiculoId,
        'categoria': categoria,
        'componente': componente,
        'descripcion': descripcion,
        'criticidad': criticidad,
        'origen': origen,
        if (rutaId != null) 'ruta_id': rutaId,
        if (trabajadorId != null) 'trabajador_id': trabajadorId,
        if (inspeccionId != null) 'inspeccion_id': inspeccionId,
      };
}

class ActualizarAveriaRequest {
  const ActualizarAveriaRequest({
    this.estado,
    this.descripcion,
    this.trabajadorId,
  });

  final String? estado;
  final String? descripcion;
  final int? trabajadorId;

  Map<String, dynamic> toJson() => {
        if (estado != null) 'estado': estado,
        if (descripcion != null) 'descripcion': descripcion,
        if (trabajadorId != null) 'trabajador_id': trabajadorId,
      };
}