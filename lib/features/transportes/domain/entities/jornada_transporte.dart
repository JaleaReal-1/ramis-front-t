class JornadaTransporte {
  const JornadaTransporte({
    this.subAcciones = const <JornadaTransporte>[],
    this.estadoSemaforo = 'verde',
    this.fotoObservacion,
    this.jornadaPadreId,
    this.galonesConsumidos,
    this.rendimientoKmGalon,
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
    this.detallesGrua,
    this.detallesCombustible,
    this.detallesMantenimiento,
    this.detallesInspeccion,
    this.detallesCocada,
    this.detallesTorque,
    this.detallesTrabajosExternos,
    this.motivoCancelacion,
    this.canceladoPorId,
  });

  final List<JornadaTransporte> subAcciones;
  final String estadoSemaforo;
  final String? fotoObservacion;
  final int? jornadaPadreId;
  final double? galonesConsumidos;
  final double? rendimientoKmGalon;
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
  final Map<String, dynamic>? detallesGrua;
  final Map<String, dynamic>? detallesCombustible;
  final Map<String, dynamic>? detallesMantenimiento;
  final Map<String, dynamic>? detallesInspeccion;
  final Map<String, dynamic>? detallesCocada;
  final Map<String, dynamic>? detallesTorque;
  final Map<String, dynamic>? detallesTrabajosExternos;
  final String? motivoCancelacion;
  final int? canceladoPorId;
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
    this.fotoIncidencia,
    this.severidad,
    required this.id,
    required this.jornadaId,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
  });

  final String? fotoIncidencia;
  final String? severidad;
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
    this.costo,
    this.comprobante,
    this.odometro,
  });

  final double? costo;
  final String? comprobante;
  final double? odometro;
  final double? galones;
  final int? nivelFinal;

  Map<String, dynamic> toJson() => {
        if (costo != null) 'costo': costo,
        if (comprobante != null) 'comprobante': comprobante,
        if (odometro != null) 'odometro': odometro,
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

class AccionInspeccionRequest {
  const AccionInspeccionRequest({
    required this.fechaInspeccion,
    required this.fechaVencimiento,
  });

  final DateTime fechaInspeccion;
  final DateTime fechaVencimiento;

  Map<String, dynamic> toJson() => {
        'fecha_inspeccion': _fechaApi(fechaInspeccion),
        'fecha_vencimiento': _fechaApi(fechaVencimiento),
      };
}

String _fechaApi(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

class AccionCocadaRequest {
  const AccionCocadaRequest({required this.medida});
  final double medida;
  Map<String, dynamic> toJson() => {'medida': medida};
}

class AccionTorqueRequest {
  const AccionTorqueRequest({required this.medida});
  final double medida;
  Map<String, dynamic> toJson() => {'medida': medida};
}

class AccionTrabajosExternosRequest {
  const AccionTrabajosExternosRequest({required this.descripcionTrabajos});
  final String descripcionTrabajos;
  Map<String, dynamic> toJson() =>
      {'descripcion_trabajos': descripcionTrabajos};
}

class RegistroAccionRequest {
  const RegistroAccionRequest({
    required this.accionTipo,
    required this.vehiculoId,
    this.kmInicial,
    this.jornadaPadreId,
    this.ruta,
    this.nivelCombustible,
    this.checklistFlash,
    required this.observaciones,
    this.tieneObservaciones = false,
    this.severidad,
    this.fotoObservacion,
    this.detallesGrua,
    this.detallesCombustible,
    this.detallesMantenimiento,
    this.detallesInspeccion,
    this.detallesCocada,
    this.detallesTorque,
    this.detallesTrabajosExternos,
    this.fotosObservacion = const [],
    this.odometroEvidenciaUrl,
    this.odometroMotivo,
  });

  final String accionTipo;
  final int vehiculoId;
  final double? kmInicial;
  final int? jornadaPadreId;
  final String? ruta;
  final int? nivelCombustible;
  final Map<String, dynamic>? checklistFlash;
  final String observaciones;
  final AccionGruaRequest? detallesGrua;
  final AccionCombustibleRequest? detallesCombustible;
  final AccionMantenimientoRequest? detallesMantenimiento;
  final AccionInspeccionRequest? detallesInspeccion;
  final AccionCocadaRequest? detallesCocada;
  final AccionTorqueRequest? detallesTorque;
  final AccionTrabajosExternosRequest? detallesTrabajosExternos;

  final bool tieneObservaciones;
  final String? severidad;
  final String? fotoObservacion;

  final List<String> fotosObservacion;
  final String? odometroEvidenciaUrl;
  final String? odometroMotivo;

  Map<String, dynamic> toJson() => {
        'fotos_observacion': fotosObservacion,
        if (odometroEvidenciaUrl != null)
          'odometro_evidencia_url': odometroEvidenciaUrl,
        if (odometroMotivo != null) 'odometro_motivo': odometroMotivo,
        'tiene_observaciones': tieneObservaciones,
        if (tieneObservaciones) 'severidad': severidad,
        if (tieneObservaciones) 'foto_observacion': fotoObservacion,
        'accion_tipo': accionTipo,
        'vehiculo_id': vehiculoId,
        if (kmInicial != null) 'km_inicial': kmInicial,
        if (jornadaPadreId != null) 'jornada_padre_id': jornadaPadreId,
        if (ruta != null) 'ruta': ruta,
        if (nivelCombustible != null) 'nivel_combustible': nivelCombustible,
        if (checklistFlash != null) 'checklist_flash': checklistFlash,
        'observaciones': observaciones.trim(),
        if (detallesGrua != null) 'detalles_grua': detallesGrua!.toJson(),
        if (detallesCombustible != null)
          'detalles_combustible': detallesCombustible!.toJson(),
        if (detallesMantenimiento != null)
          'detalles_mantenimiento': detallesMantenimiento!.toJson(),
        if (detallesInspeccion != null)
          'detalles_inspeccion': detallesInspeccion!.toJson(),
        if (detallesCocada != null) 'detalles_cocada': detallesCocada!.toJson(),
        if (detallesTorque != null) 'detalles_torque': detallesTorque!.toJson(),
        if (detallesTrabajosExternos != null)
          'detalles_trabajos_externos': detallesTrabajosExternos!.toJson(),
      };
}

class ChecklistRequest {
  const ChecklistRequest({
    required this.kilometraje,
    required this.nivelCombustible,
    required this.estadoGeneral,
    required this.conforme,
    this.observaciones,
    this.tieneObservaciones = false,
    this.severidad,
    this.fotoObservacion,
    this.tipo = 'inicial',
    this.fotosObservacion = const [],
    this.odometroEvidenciaUrl,
    this.odometroMotivo,
  });

  final double kilometraje;
  final String nivelCombustible;
  final String estadoGeneral;
  final bool conforme;
  final String? observaciones;
  final String tipo;
  final List<String> fotosObservacion;
  final String? odometroEvidenciaUrl;
  final String? odometroMotivo;

  final bool tieneObservaciones;
  final String? severidad;
  final String? fotoObservacion;

  Map<String, dynamic> toJson() => {
        'fotos_observacion': fotosObservacion,
        if (odometroEvidenciaUrl != null)
          'odometro_evidencia_url': odometroEvidenciaUrl,
        if (odometroMotivo != null) 'odometro_motivo': odometroMotivo,
        'tiene_observaciones': tieneObservaciones,
        if (tieneObservaciones) 'severidad': severidad,
        if (tieneObservaciones) 'foto_observacion': fotoObservacion,
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
    this.severidad,
    this.fotoIncidencia,
    required this.tipo,
    required this.descripcion,
    this.fotos = const [],
  });

  final String? severidad;
  final String? fotoIncidencia;
  final String tipo;
  final String descripcion;
  final List<String> fotos;

  Map<String, dynamic> toJson() => {
        'fotos': fotos,
        'fecha': DateTime.now().toUtc().toIso8601String(),
        if (severidad != null) 'severidad': severidad,
        if (fotoIncidencia != null) 'foto_incidencia': fotoIncidencia,
        'tipo': tipo,
        'descripcion': descripcion,
      };
}
