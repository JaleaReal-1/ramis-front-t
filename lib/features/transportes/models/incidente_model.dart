class IncidenteModel {
  const IncidenteModel({
    required this.id,
    required this.vehiculoId,
    required this.trabajadorId,
    required this.tipo,
    required this.ubicacion,
    required this.descripcion,
    required this.hayDanos,
    required this.hayPersonasAfectadas,
    required this.fecha,
    required this.estado,
    this.rutaId,
    this.fechaBaja,
    this.usuarioBaja,
  });

  final int id;
  final int vehiculoId;
  final int trabajadorId;
  final String tipo;
  final String ubicacion;
  final String descripcion;
  final bool hayDanos;
  final bool hayPersonasAfectadas;
  final DateTime fecha;
  final String estado;
  final int? rutaId;
  final DateTime? fechaBaja;
  final int? usuarioBaja;

  factory IncidenteModel.fromJson(Map<String, dynamic> json) {
    return IncidenteModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      trabajadorId: json['trabajador_id'] as int,
      tipo: json['tipo'] as String,
      ubicacion: json['ubicacion'] as String,
      descripcion: json['descripcion'] as String,
      hayDanos: json['hay_danos'] as bool,
      hayPersonasAfectadas: json['hay_personas_afectadas'] as bool,
      fecha: DateTime.parse(json['fecha'] as String),
      estado: json['estado'] as String,
      rutaId: json['ruta_id'] as int?,
      fechaBaja: json['fecha_baja'] == null
          ? null
          : DateTime.tryParse(json['fecha_baja'] as String),
      usuarioBaja: json['usuario_baja'] as int?,
    );
  }
}

/// Respuesta simplificada para listados
class IncidenteListModel {
  const IncidenteListModel({
    required this.id,
    required this.vehiculoId,
    required this.tipo,
    required this.fecha,
    required this.ubicacion,
    required this.estado,
    required this.hayDanos,
    required this.hayPersonasAfectadas,
  });

  final int id;
  final int vehiculoId;
  final String tipo;
  final DateTime fecha;
  final String ubicacion;
  final String estado;
  final bool hayDanos;
  final bool hayPersonasAfectadas;

  factory IncidenteListModel.fromJson(Map<String, dynamic> json) {
    return IncidenteListModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      tipo: json['tipo'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      ubicacion: json['ubicacion'] as String,
      estado: json['estado'] as String,
      hayDanos: json['hay_danos'] as bool,
      hayPersonasAfectadas: json['hay_personas_afectadas'] as bool,
    );
  }
}

class CrearIncidenteRequest {
  const CrearIncidenteRequest({
    required this.vehiculoId,
    required this.trabajadorId,
    required this.tipo,
    required this.ubicacion,
    required this.descripcion,
    this.rutaId,
    this.hayDanos = false,
    this.hayPersonasAfectadas = false,
    this.generarAveria = false,
    this.averiaCategoria,
    this.averiaComponente,
    this.averiaCriticidad,
    this.averiaDescripcion,
  });

  final int vehiculoId;
  final int trabajadorId;
  final String tipo;
  final String ubicacion;
  final String descripcion;
  final int? rutaId;
  final bool hayDanos;
  final bool hayPersonasAfectadas;
  final bool generarAveria;
  final String? averiaCategoria;
  final String? averiaComponente;
  final String? averiaCriticidad;
  final String? averiaDescripcion;

  Map<String, dynamic> toJson() => {
        'vehiculo_id': vehiculoId,
        'trabajador_id': trabajadorId,
        'tipo': tipo,
        'ubicacion': ubicacion,
        'descripcion': descripcion,
        if (rutaId != null) 'ruta_id': rutaId,
        'hay_danos': hayDanos,
        'hay_personas_afectadas': hayPersonasAfectadas,
        'generar_averia': generarAveria,
        if (averiaCategoria != null) 'averia_categoria': averiaCategoria,
        if (averiaComponente != null) 'averia_componente': averiaComponente,
        if (averiaCriticidad != null) 'averia_criticidad': averiaCriticidad,
        if (averiaDescripcion != null) 'averia_descripcion': averiaDescripcion,
      };
}

class ActualizarIncidenteRequest {
  const ActualizarIncidenteRequest({
    this.estado,
    this.descripcion,
    this.hayDanos,
    this.hayPersonasAfectadas,
  });

  final String? estado;
  final String? descripcion;
  final bool? hayDanos;
  final bool? hayPersonasAfectadas;

  Map<String, dynamic> toJson() => {
        if (estado != null) 'estado': estado,
        if (descripcion != null) 'descripcion': descripcion,
        if (hayDanos != null) 'hay_danos': hayDanos,
        if (hayPersonasAfectadas != null)
          'hay_personas_afectadas': hayPersonasAfectadas,
      };
}