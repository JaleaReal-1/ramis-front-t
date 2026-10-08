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
    this.kmInicial,
    this.kmFinal,
    this.horasEfectivas,
    this.alertaHoras = false,
    this.alertaKm = false,
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
  final double? kmInicial;
  final double? kmFinal;
  final double? horasEfectivas;
  final bool alertaHoras;
  final bool alertaKm;
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

class AccionGruaRequest {
  const AccionGruaRequest({
    this.actividad,
    this.horometroInicial,
    this.horometroFinal,
  });

  final String? actividad;
  final double? horometroInicial;
  final double? horometroFinal;

  Map<String, dynamic> toJson() => {
        if (actividad != null) 'actividad': actividad,
        if (horometroInicial != null) 'horometro_inicial': horometroInicial,
        if (horometroFinal != null) 'horometro_final': horometroFinal,
      };
}

class AccionCombustibleRequest {
  const AccionCombustibleRequest({
    this.galones,
    this.nivelFinal,
  });

  final double? galones;
  final int? nivelFinal;

  Map<String, dynamic> toJson() => {
        if (galones != null) 'galones': galones,
        if (nivelFinal != null) 'nivel_final': nivelFinal,
      };
}

class AccionMantenimientoRequest {
  const AccionMantenimientoRequest({
    this.taller,
    this.tipo,
    this.trabajosPreventivos,
    this.descripcionCorrectivo,
  });

  final String? taller;
  final String? tipo;
  final List<String>? trabajosPreventivos;
  final String? descripcionCorrectivo;

  Map<String, dynamic> toJson() => {
        if (taller != null) 'taller': taller,
        if (tipo != null) 'tipo': tipo,
        if (trabajosPreventivos != null)
          'trabajos_preventivos': trabajosPreventivos,
        if (descripcionCorrectivo != null)
          'descripcion_correctivo': descripcionCorrectivo,
      };
}

class RegistroAccionRequest {
  const RegistroAccionRequest({
    required this.accionTipo,
    required this.vehiculoId,
    this.ruta,
    required this.nivelCombustible,
    this.checklistFlash,
    this.observaciones,
    this.detallesGrua,
    this.detallesCombustible,
    this.detallesMantenimiento,
  });

  final String accionTipo;
  final int vehiculoId;
  final String? ruta;
  final int nivelCombustible;
  final Map<String, dynamic>? checklistFlash;
  final String? observaciones;
  final AccionGruaRequest? detallesGrua;
  final AccionCombustibleRequest? detallesCombustible;
  final AccionMantenimientoRequest? detallesMantenimiento;

  Map<String, dynamic> toJson() => {
        'accion_tipo': accionTipo,
        'vehiculo_id': vehiculoId,
        if (ruta != null) 'ruta': ruta,
        'nivel_combustible': nivelCombustible,
        if (checklistFlash != null) 'checklist_flash': checklistFlash,
        if (observaciones != null && observaciones!.trim().isNotEmpty)
          'observaciones': observaciones,
        if (detallesGrua != null) 'detalles_grua': detallesGrua!.toJson(),
        if (detallesCombustible != null)
          'detalles_combustible': detallesCombustible!.toJson(),
        if (detallesMantenimiento != null)
          'detalles_mantenimiento': detallesMantenimiento!.toJson(),
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
