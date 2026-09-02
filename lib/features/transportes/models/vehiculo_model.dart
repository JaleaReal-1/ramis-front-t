class VehiculoModel {
  const VehiculoModel({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.capacidadCarga,
    required this.estado,
    this.kilometrajeActual,
    this.fechaBaja,
    this.usuarioBaja,
  });

  final int id;
  final String placa;
  final String marca;
  final String modelo;
  final double capacidadCarga;
  final String estado;
  final double? kilometrajeActual;
  final DateTime? fechaBaja;
  final int? usuarioBaja;

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id: json['id'] as int,
      placa: json['placa'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      capacidadCarga: (json['capacidad_carga'] as num).toDouble(),
      estado: json['estado'] as String,
      kilometrajeActual: _number(json['kilometraje_actual']),
      fechaBaja: _parseDate(json['fecha_baja']),
      usuarioBaja: json['usuario_baja'] as int?,
    );
  }

  static double? _number(dynamic value) =>
      value == null ? null : (value as num).toDouble();

  static DateTime? _parseDate(dynamic value) {
    return value == null ? null : DateTime.tryParse(value as String);
  }
}

class CrearVehiculoRequest {
  const CrearVehiculoRequest({
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.capacidadCarga,
  });

  final String placa;
  final String marca;
  final String modelo;
  final double capacidadCarga;

  Map<String, dynamic> toJson() => {
        'placa': placa,
        'marca': marca,
        'modelo': modelo,
        'capacidad_carga': capacidadCarga,
      };
}

class ActualizarVehiculoRequest {
  const ActualizarVehiculoRequest({
    this.placa,
    this.marca,
    this.modelo,
    this.capacidadCarga,
  });

  final String? placa;
  final String? marca;
  final String? modelo;
  final double? capacidadCarga;

  Map<String, dynamic> toJson() => {
        if (placa != null) 'placa': placa,
        if (marca != null) 'marca': marca,
        if (modelo != null) 'modelo': modelo,
        if (capacidadCarga != null) 'capacidad_carga': capacidadCarga,
      };
}
