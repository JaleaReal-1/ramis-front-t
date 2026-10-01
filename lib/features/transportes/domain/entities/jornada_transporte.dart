class JornadaTransporte {
  const JornadaTransporte({
    required this.id,
    required this.conductorId,
    required this.estado,
    this.vehiculoId,
    this.fechaInicio,
    this.fechaFin,
    this.checklists = const <Checklist>[],
    this.incidencias = const <IncidenciaRuta>[],
    this.accionTipo,
    this.ruta,
    this.nivelCombustible,
    this.checklistFlash,
    this.observaciones,
  });

  final int id;
  final int? vehiculoId;
  final int conductorId;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final List<Checklist> checklists;
  final List<IncidenciaRuta> incidencias;
  final String? accionTipo;
  final String? ruta;
  final int? nivelCombustible;
  final Map<String, dynamic>? checklistFlash;
  final String? observaciones;
}

class Checklist {
  const Checklist({
    required this.id,
    required this.jornadaId,
    required this.tipo,
    required this.kilometraje,
    required this.nivelCombustible,
    required this.estadoGeneral,
    required this.conforme,
    this.observaciones,
  });

  final int id;
  final int jornadaId;
  final String tipo;
  final double kilometraje;
  final String nivelCombustible;
  final String estadoGeneral;
  final bool conforme;
  final String? observaciones;
}

class IncidenciaRuta {
  const IncidenciaRuta({
    required this.id,
    required this.jornadaId,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
  });

  final int id;
  final int jornadaId;
  final String tipo;
  final String descripcion;
  final DateTime fecha;
}

class AsignarJornadaRequest {
  const AsignarJornadaRequest({
    required this.vehiculoId,
    required this.conductorId,
  });

  final int vehiculoId;
  final int conductorId;

  Map<String, dynamic> toJson() => {
        'vehiculo_id': vehiculoId,
        'conductor_id': conductorId,
      };
}

class RegistroAccionRequest {
  const RegistroAccionRequest({
    required this.accionTipo,
    this.vehiculoId,
    this.ruta,
    this.nivelCombustible,
    this.checklistFlash,
    this.observaciones,
  });

  final String accionTipo;
  final int? vehiculoId;
  final String? ruta;
  final int? nivelCombustible;
  final Map<String, dynamic>? checklistFlash;
  final String? observaciones;

  Map<String, dynamic> toJson() => {
        'accion_tipo': accionTipo,
        if (vehiculoId != null) 'vehiculo_id': vehiculoId,
        if (ruta != null) 'ruta': ruta,
        if (nivelCombustible != null) 'nivel_combustible': nivelCombustible,
        if (checklistFlash != null) 'checklist_flash': checklistFlash,
        if (observaciones != null && observaciones!.trim().isNotEmpty)
          'observaciones': observaciones,
      };
}

class ChecklistRequest {
  const ChecklistRequest({
    required this.kilometraje,
    required this.nivelCombustible,
    required this.estadoGeneral,
    required this.conforme,
    this.observaciones,
    this.tipo = 'inicial',
  });

  final double kilometraje;
  final String nivelCombustible;
  final String estadoGeneral;
  final bool conforme;
  final String? observaciones;
  final String tipo;

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'kilometraje': kilometraje,
        'nivel_combustible': nivelCombustible,
        'estado_general': estadoGeneral,
        'conforme': conforme,
        if (observaciones != null && observaciones!.trim().isNotEmpty)
          'observaciones': observaciones,
      };
}

class IncidenciaRutaRequest {
  const IncidenciaRutaRequest({
    required this.tipo,
    required this.descripcion,
  });

  final String tipo;
  final String descripcion;

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'descripcion': descripcion,
      };
}
