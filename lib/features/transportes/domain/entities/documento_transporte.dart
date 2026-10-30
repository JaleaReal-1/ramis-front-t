const documentosConductor = {
  'licencia': 'Licencia de Conducir',
  'emo': 'EMO (Examen Médico Ocupacional)',
  'pase_minero': 'Pase Minero San Rafael / Minsur',
};
const documentosVehiculo = {
  'soat': 'SOAT',
  'revision_tecnica': 'Revisión Técnica',
  'seguro_sctr': 'Póliza de Seguro',
  'tarjeta_propiedad': 'Tarjeta de Propiedad',
  'pase_minero': 'Pase Minero de Unidad',
};

class DocumentoTransporte {
  DocumentoTransporte.fromJson(Map<String, dynamic> json)
      : tipo = json['tipo'] as String,
        id = (json['documento_id'] as num?)?.toInt(),
        fecha = DateTime.tryParse('${json['fecha_vencimiento'] ?? ''}'),
        archivo = json['archivo_url'] as String?,
        categoria = json['licencia_categoria'] as String?,
        estado = (json['estado_documento'] ?? 'pendiente') as String,
        semaforo =
            (json['semaforo'] ?? json['estado'] ?? 'pendiente') as String,
        motivo = json['motivo_rechazo'] as String?,
        diasServidor = (json['dias_restantes'] as num?)?.toInt();
  final String tipo, estado, semaforo;
  final int? id, diasServidor;
  final DateTime? fecha;
  final String? archivo, categoria, motivo;
  int? get dias {
    if (diasServidor != null) return diasServidor;
    if (fecha == null) return null;
    final lima = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    return DateTime.utc(fecha!.year, fecha!.month, fecha!.day)
        .difference(DateTime.utc(lima.year, lima.month, lima.day))
        .inDays;
  }

  String get vencimiento => fecha == null
      ? 'Sin fecha registrada'
      : '${fecha!.day.toString().padLeft(2, '0')}/${fecha!.month.toString().padLeft(2, '0')}/${fecha!.year}';
}
