class RutaAsignacionModel {
  const RutaAsignacionModel({
    required this.id,
    required this.vehiculoId,
    required this.trabajadorId,
    required this.origen,
    required this.destino,
    required this.fechaSalida,
    required this.fechaLlegadaEstimada,
    required this.estadoRuta,
    this.kilometrajeSalida,
    this.kilometrajeLlegada,
    this.combustibleSalida,
    this.combustibleLlegada,
    this.observacionesSalida,
    this.observacionesLlegada,
    this.firmaTrabajador,
    this.checkLlantas,
    this.checkFrenos,
    this.checkLuces,
    this.fechaBaja,
    this.usuarioBaja,
  });

  final int id;
  final int vehiculoId;
  final int trabajadorId;
  final String origen;
  final String destino;
  final DateTime fechaSalida;
  final DateTime fechaLlegadaEstimada;
  final String estadoRuta;
  final double? kilometrajeSalida;
  final double? kilometrajeLlegada;
  final String? combustibleSalida;
  final String? combustibleLlegada;
  final String? observacionesSalida;
  final String? observacionesLlegada;
  final String? firmaTrabajador;
  final bool? checkLlantas;
  final bool? checkFrenos;
  final bool? checkLuces;
  final DateTime? fechaBaja;
  final int? usuarioBaja;

  factory RutaAsignacionModel.fromJson(Map<String, dynamic> json) {
    return RutaAsignacionModel(
      id: json['id'] as int,
      vehiculoId: json['vehiculo_id'] as int,
      trabajadorId: json['trabajador_id'] as int,
      origen: json['origen'] as String,
      destino: json['destino'] as String,
      fechaSalida: DateTime.parse(json['fecha_salida'] as String),
      fechaLlegadaEstimada:
          DateTime.parse(json['fecha_llegada_estimada'] as String),
      estadoRuta: json['estado_ruta'] as String,
      kilometrajeSalida: _number(json['kilometraje_salida']),
      kilometrajeLlegada: _number(json['kilometraje_llegada']),
      combustibleSalida: json['combustible_salida'] as String?,
      combustibleLlegada: json['combustible_llegada'] as String?,
      observacionesSalida: json['observaciones_salida'] as String?,
      observacionesLlegada: json['observaciones_llegada'] as String?,
      firmaTrabajador: json['firma_trabajador'] as String?,
      checkLlantas: json['check_llantas'] as bool?,
      checkFrenos: json['check_frenos'] as bool?,
      checkLuces: json['check_luces'] as bool?,
      fechaBaja: _date(json['fecha_baja']),
      usuarioBaja: json['usuario_baja'] as int?,
    );
  }

  static double? _number(dynamic value) =>
      value == null ? null : (value as num).toDouble();

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value as String);
}

class CrearRutaRequest {
  const CrearRutaRequest({
    required this.vehiculoId,
    required this.trabajadorId,
    required this.origen,
    required this.destino,
    required this.fechaSalida,
    required this.fechaLlegadaEstimada,
    this.observacionesSalida,
  });

  final int vehiculoId;
  final int trabajadorId;
  final String origen;
  final String destino;
  final DateTime fechaSalida;
  final DateTime fechaLlegadaEstimada;
  final String? observacionesSalida;

  Map<String, dynamic> toJson() => {
        'vehiculo_id': vehiculoId,
        'trabajador_id': trabajadorId,
        'origen': origen,
        'destino': destino,
        'fecha_salida': fechaSalida.toIso8601String(),
        'fecha_llegada_estimada': fechaLlegadaEstimada.toIso8601String(),
        if (observacionesSalida != null)
          'observaciones_salida': observacionesSalida,
      };
}

class ActualizarRutaRequest {
  const ActualizarRutaRequest({
    this.origen,
    this.destino,
    this.fechaSalida,
    this.fechaLlegadaEstimada,
    this.vehiculoId,
    this.trabajadorId,
    this.observacionesSalida,
  });

  final String? origen;
  final String? destino;
  final DateTime? fechaSalida;
  final DateTime? fechaLlegadaEstimada;
  final int? vehiculoId;
  final int? trabajadorId;
  final String? observacionesSalida;

  Map<String, dynamic> toJson() => {
        if (origen != null) 'origen': origen,
        if (destino != null) 'destino': destino,
        if (fechaSalida != null) 'fecha_salida': fechaSalida!.toIso8601String(),
        if (fechaLlegadaEstimada != null)
          'fecha_llegada_estimada': fechaLlegadaEstimada!.toIso8601String(),
        if (vehiculoId != null) 'vehiculo_id': vehiculoId,
        if (trabajadorId != null) 'trabajador_id': trabajadorId,
        if (observacionesSalida != null)
          'observaciones_salida': observacionesSalida,
      };
}

class IniciarRutaRequest {
  const IniciarRutaRequest({
    required this.firmaTrabajador,
    required this.checkLlantas,
    required this.checkFrenos,
    required this.checkLuces,
    required this.kilometrajeSalida,
    required this.combustibleSalida,
    this.observacionesSalida,
  });

  final String firmaTrabajador;
  final bool checkLlantas;
  final bool checkFrenos;
  final bool checkLuces;
  final double kilometrajeSalida;
  final String combustibleSalida;
  final String? observacionesSalida;

  Map<String, dynamic> toJson() => {
        'firma_trabajador': firmaTrabajador,
        'check_llantas': checkLlantas,
        'check_frenos': checkFrenos,
        'check_luces': checkLuces,
        'kilometraje_salida': kilometrajeSalida,
        'combustible_salida': combustibleSalida,
        if (observacionesSalida != null)
          'observaciones_salida': observacionesSalida,
      };
}

class FinalizarRutaRequest {
  const FinalizarRutaRequest({
    required this.kilometrajeLlegada,
    required this.combustibleLlegada,
    required this.observacionesLlegada,
  });

  final double kilometrajeLlegada;
  final String combustibleLlegada;
  final String observacionesLlegada;

  Map<String, dynamic> toJson() => {
        'kilometraje_llegada': kilometrajeLlegada,
        'combustible_llegada': combustibleLlegada,
        'observaciones_llegada': observacionesLlegada,
      };
}
