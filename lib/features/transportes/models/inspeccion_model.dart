class ChecklistItemModel {
  const ChecklistItemModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.criticidad,
    required this.orden,
    required this.activo,
  });

  final int id;
  final String nombre;
  final String categoria;
  final String criticidad;
  final int orden;
  final bool activo;

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String,
      criticidad: json['criticidad'] as String,
      orden: json['orden'] as int,
      activo: json['activo'] as bool,
    );
  }
}

class InspeccionDetalleModel {
  const InspeccionDetalleModel({
    required this.id,
    required this.inspeccionId,
    required this.checklistItemId,
    required this.resultadoItem,
    this.checklistItem,
  });

  final int id;
  final int inspeccionId;
  final int checklistItemId;
  final String resultadoItem;
  final ChecklistItemModel? checklistItem;

  factory InspeccionDetalleModel.fromJson(Map<String, dynamic> json) {
    return InspeccionDetalleModel(
      id: json['id'] as int,
      inspeccionId: json['inspeccion_id'] as int,
      checklistItemId: json['checklist_item_id'] as int,
      resultadoItem: json['resultado_item'] as String,
      checklistItem: json['checklist_item'] != null
          ? ChecklistItemModel.fromJson(
              json['checklist_item'] as Map<String, dynamic>)
          : null,
    );
  }
}

class InspeccionModel {
  const InspeccionModel({
    required this.id,
    required this.vehiculoId,
    required this.trabajadorId,
    required this.tipo,
    required this.fecha,
    required this.kilometraje,
    required this.combustible,
    this.observaciones,
    this.rutaId,
    this.firma,
    required this.resultado,
    this.detalles,
  });

  final int id;
  final int vehiculoId;
  final int trabajadorId;
  final String tipo;
  final DateTime fecha;
  final double kilometraje;
  final String combustible;
  final String? observaciones;
  final int? rutaId;
  final String? firma;
  final String resultado;
  final List<InspeccionDetalleModel>? detalles;

  factory InspeccionModel.fromJson(Map<String, dynamic> json) {
    return InspeccionModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      trabajadorId: json['trabajador_id'] as int,
      tipo: json['tipo'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      kilometraje: (json['kilometraje'] as num).toDouble(),
      combustible: json['combustible'] as String,
      observaciones: json['observaciones'] as String?,
      rutaId: json['ruta_id'] as int?,
      firma: json['firma'] as String?,
      resultado: json['resultado'] as String,
      detalles: (json['detalles'] as List<dynamic>?)
          ?.map((d) =>
              InspeccionDetalleModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Respuesta simplificada para listados
class InspeccionListModel {
  const InspeccionListModel({
    required this.id,
    required this.vehiculoId,
    required this.tipo,
    required this.fecha,
    required this.resultado,
    required this.trabajadorId,
    this.rutaId,
  });

  final int id;
  final int vehiculoId;
  final String tipo;
  final DateTime fecha;
  final String resultado;
  final int trabajadorId;
  final int? rutaId;

  factory InspeccionListModel.fromJson(Map<String, dynamic> json) {
    return InspeccionListModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      tipo: json['tipo'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      resultado: json['resultado'] as String,
      trabajadorId: json['trabajador_id'] as int,
      rutaId: json['ruta_id'] as int?,
    );
  }
}

class InspeccionDetalleCreate {
  const InspeccionDetalleCreate({
    required this.checklistItemId,
    required this.resultadoItem,
  });

  final int checklistItemId;
  final String resultadoItem;

  Map<String, dynamic> toJson() => {
        'checklist_item_id': checklistItemId,
        'resultado_item': resultadoItem,
      };
}

class CrearInspeccionRequest {
  const CrearInspeccionRequest({
    required this.vehiculoId,
    required this.trabajadorId,
    required this.tipo,
    required this.kilometraje,
    required this.combustible,
    required this.detalles,
    this.rutaId,
    this.firma,
    this.observaciones,
  });

  final int vehiculoId;
  final int trabajadorId;
  final String tipo;
  final double kilometraje;
  final String combustible;
  final List<InspeccionDetalleCreate> detalles;
  final int? rutaId;
  final String? firma;
  final String? observaciones;

  Map<String, dynamic> toJson() => {
        'vehiculo_id': vehiculoId,
        'trabajador_id': trabajadorId,
        'tipo': tipo,
        'kilometraje': kilometraje,
        'combustible': combustible,
        'detalles': detalles.map((d) => d.toJson()).toList(),
        if (rutaId != null) 'ruta_id': rutaId,
        if (firma != null) 'firma': firma,
        if (observaciones != null) 'observaciones': observaciones,
      };
}

class ActualizarInspeccionRequest {
  const ActualizarInspeccionRequest({this.observaciones});

  final String? observaciones;

  Map<String, dynamic> toJson() => {
        if (observaciones != null) 'observaciones': observaciones,
      };
}