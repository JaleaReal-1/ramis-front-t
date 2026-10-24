import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import '../../domain/entities/jornada_transporte.dart';
import '../../providers/jornadas_provider.dart';
import '../widgets/checklist_form.dart';
import '../widgets/observacion_fields.dart';
import '../widgets/registro_accion_form.dart';
import '../../data/repositories/transporte_repository_impl.dart';
import '../widgets/subaccion_controls.dart';

class MiJornadaScreen extends ConsumerStatefulWidget {
  const MiJornadaScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  ConsumerState<MiJornadaScreen> createState() => _MiJornadaScreenState();
}

class _MiJornadaScreenState extends ConsumerState<MiJornadaScreen> {
  JornadaTransporte? _cerrada;

  Future<void> _actualizar() async {
    ref.invalidate(accionesRegistradasProvider);
    ref.invalidate(vehiculosDisponiblesProvider);
    final refreshed = ref.refresh(miJornadaProvider.future);
    await refreshed;
  }

  @override
  Widget build(BuildContext context) {
    final jornada = ref.watch(miJornadaProvider);
    final body = jornada.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('No se pudo cargar la jornada: $e'),
        TextButton(onPressed: _actualizar, child: const Text('Reintentar')),
      ])),
      data: (j) => RefreshIndicator(
          onRefresh: _actualizar,
          child: j == null ? _sinJornada() : _consola(j)),
    );
    return widget.embedded
        ? body
        : Scaffold(
            appBar:
                AppBar(title: const Text('Seguimiento de la Jornada Actual')),
            body: body);
  }

  Widget _sinJornada() => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (_cerrada case final cerrada?)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jornada finalizada',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                'Recorrido: ${((cerrada.kmFinal ?? 0) - (cerrada.kmInicial ?? 0)).toStringAsFixed(1)} km'),
                            Text(
                                'Consumo: ${cerrada.galonesConsumidos?.toStringAsFixed(2) ?? "Sin estimación"} gal'),
                            Text(
                                'Rendimiento: ${cerrada.rendimientoKmGalon?.toStringAsFixed(2) ?? "Sin estimación"} km/gal'),
                          ]))),
            const Text('No tienes una jornada activa en este momento.'),
            const SizedBox(height: 20),
            FilledButton.icon(
                icon: const Icon(Icons.local_shipping),
                label: const Text('Empezar a Conducir'),
                onPressed: () async {
                  await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => Scaffold(
                              appBar:
                                  AppBar(title: const Text('Abrir jornada')),
                              body: RegistroAccionForm(
                                  soloApertura: true,
                                  onRegistered: () => Navigator.pop(ctx)))));
                  if (mounted) {
                    setState(() => _cerrada = null);
                    await _actualizar();
                  }
                }),
            const SizedBox(height: 12),
            const Text(
                'Registra el vehículo, el odómetro inicial, el combustible y el checklist para empezar tu jornada.'),
          ]);

  Widget _consola(JornadaTransporte j) {
    final vehiculo = ref.watch(vehiculoJornadaProvider(j.vehiculoId!));
    final v = vehiculo.value;
    final color = v?['estado_semaforo'] as String? ?? j.estadoSemaforo;
    final conductor = ref.watch(currentUserForTransportProvider).value;
    final eventos = <_Evento>[
      _Evento(
          j.fechaInicio,
          'Apertura de jornada',
          'Odómetro inicial: ${j.kmInicial ?? "Pendiente"} km',
          j.fotoObservacion,
          j.estadoSemaforo),
      for (final a in j.subAcciones)
        _Evento(a.fechaInicio, a.accionTipo ?? 'Actividad', _resumen(a),
            a.fotoObservacion, a.estadoSemaforo),
      for (final i in j.incidencias)
        _Evento(
            i.fecha,
            'Observación en ruta',
            i.descripcion,
            i.fotoIncidencia,
            i.severidad == 'critica' || i.severidad == 'grave'
                ? 'rojo'
                : i.severidad == 'moderada'
                    ? 'amarillo'
                    : 'verde'),
    ].where((evento) {
      if (evento.fecha == null) return false;
      final fecha = _local(evento.fecha!);
      final hoy = DateTime.now();
      return fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day;
    }).toList()
      ..sort((a, b) => a.fecha!.compareTo(b.fecha!));
    return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (['pendiente_de_cierre', 'cerrada_por_sistema'].contains(j.estado))
            const Card(
                color: Color(0xFFFFF3CD),
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Odómetro pendiente de cierre. Regularice esta jornada para poder tomar otro vehículo.'))),
          for (final sub in j.subAcciones)
            if (sub.estado == 'en_curso' || sub.estado == 'cancelada')
              SubaccionControls(subaccion: sub, onChanged: _actualizar),
          Text(
              j.estado == 'en_curso'
                  ? 'Mi jornada en curso'
                  : 'Jornada asignada',
              style: AppTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            v == null
                                ? 'Vehículo #${j.vehiculoId}'
                                : '${v['placa']} · ${v['tipo'] ?? v['modelo']}',
                            style: AppTheme.titleMedium),
                        if (vehiculo.hasError)
                          TextButton(
                              onPressed: () => ref.invalidate(
                                  vehiculoJornadaProvider(j.vehiculoId!)),
                              child:
                                  const Text('Reintentar datos del vehículo')),
                        Text(conductor == null
                            ? 'Conductor #${j.conductorId}'
                            : '${conductor.nombre} ${conductor.apellidos}'),
                        Text('Inicio: ${_fecha(j.fechaInicio)}'),
                        Text(
                            'Odómetro inicial: ${j.kmInicial ?? "Pendiente"} km'),
                        Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.circle, color: colorSemaforo(color)),
                              Text(switch (color) {
                                'rojo' => 'Rojo · Vehículo inoperativo',
                                'amarillo' =>
                                  'Amarillo · Observaciones pendientes',
                                _ => 'Verde · Buen estado'
                              })
                            ]),
                        if (color == 'rojo')
                          const Text(
                              'La unidad está inoperativa. La jornada permanece abierta para registrar novedades y efectuar el cierre.',
                              style: TextStyle(color: Colors.red)),
                        if (v?['observaciones_pendientes'] != null)
                          Text(v!['observaciones_pendientes'] as String),
                      ]))),
          if (j.estado == 'pendiente')
            FilledButton(
                onPressed: () => _checklist(j, 'inicial', v),
                child: const Text('Checklist de apertura')),
          if (j.estado == 'en_curso') ...[
            const SizedBox(height: 16),
            const Text('Acciones en ruta · Sin finalizar la jornada'),
            const SizedBox(height: 8),
            FilledButton.icon(
                onPressed: () => _reportar(j),
                icon: const Icon(Icons.warning_amber),
                label: const Text('Reportar Observación')),
            OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => Scaffold(
                              appBar: AppBar(
                                  title: const Text('Sub-acción en ruta')),
                              body: RegistroAccionForm(
                                  jornada: j,
                                  onRegistered: () => Navigator.pop(ctx)))));
                  if (mounted) await _actualizar();
                },
                icon: const Icon(Icons.add),
                label: const Text('Registrar Sub-Acción en Ruta')),
          ],
          const SizedBox(height: 20),
          Text('Línea de tiempo de hoy', style: AppTheme.titleMedium),
          if (eventos.isEmpty)
            const Text('Aún no hay actividades registradas hoy.'),
          for (final e in eventos)
            Card(
                child: ExpansionTile(
              leading:
                  Icon(Icons.circle, size: 14, color: colorSemaforo(e.color)),
              title: Text(e.titulo),
              subtitle: Text(_fecha(e.fecha)),
              children: [
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(e.descripcion)),
                if (e.foto != null) FotoObservacion(url: e.foto!)
              ],
            )),
          if (['en_curso', 'pendiente_de_cierre', 'cerrada_por_sistema']
              .contains(j.estado))
            Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton.icon(
                    onPressed: () => _checklist(j, 'final', v),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Finalizar Jornada'))),
        ]);
  }

  Future<void> _checklist(
      JornadaTransporte j, String tipo, Map<String, dynamic>? v) async {
    // Obtain the current odometer on every attempt; never fall back to zero on failure.
    try {
      final vehiculo = await ref
          .read(transporteRepositoryProvider)
          .obtenerVehiculo(j.vehiculoId!);
      if (!mounted) return;
      await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (ctx) => ChecklistForm(
              jornadaId: j.id,
              tipo: tipo,
              kilometrajeBase: ['pendiente_de_cierre', 'cerrada_por_sistema']
                      .contains(j.estado)
                  ? (j.kmInicial ?? 0)
                  : (vehiculo['kilometraje_actual'] as num).toDouble(),
              kmInicial: j.kmInicial,
              nivelInicial: j.nivelCombustible,
              capacidadTanque:
                  (vehiculo['capacidad_tanque_galones'] as num?)?.toDouble(),
              galonesAbastecidos: j.subAcciones.fold<double>(
                  0,
                  (total, a) =>
                      total +
                      ((a.detallesCombustible?['galones'] as num?)
                              ?.toDouble() ??
                          0)),
              onSubmit: (request) async {
                try {
                  final repo = ref.read(transporteRepositoryProvider);
                  final resultado = tipo == 'final'
                      ? await repo.registrarChecklistFinal(j.id, request)
                      : await repo.registrarChecklistInicial(j.id, request);
                  if (!mounted) return;
                  if (tipo == 'final') setState(() => _cerrada = resultado);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ref.invalidate(vehiculoJornadaProvider(j.vehiculoId!));
                  await _actualizar();
                } catch (e) {
                  if (mounted) _error(e);
                }
              }));
    } catch (e) {
      if (mounted) _error(e);
    }
  }

  Future<void> _reportar(JornadaTransporte j) async {
    final form = GlobalKey<FormState>();
    bool activa = false;
    bool enviando = false;
    String severidad = 'leve';
    String descripcion = '';
    String? foto;
    List<String> fotos = [];
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                  scrollable: true,
                  title: const Text('Reportar Observación en Ruta'),
                  content: Form(
                      key: form,
                      child: ObservacionFields(
                          onPhotosChanged: (value) => fotos = value,
                          onChanged: (valor, nivel, texto, url) {
                            activa = valor;
                            severidad = nivel;
                            descripcion = texto;
                            foto = url;
                          })),
                  actions: [
                    TextButton(
                        onPressed: enviando ? null : () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: enviando
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                if (!activa) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Active las observaciones para registrar una novedad.')));
                                  return;
                                }
                                update(() => enviando = true);
                                try {
                                  await ref
                                      .read(transporteRepositoryProvider)
                                      .registrarIncidencia(
                                          j.id,
                                          IncidenciaRutaRequest(
                                              tipo: 'falla',
                                              severidad: severidad,
                                              fotoIncidencia: foto,
                                              fotos: fotos,
                                              descripcion: descripcion.trim()));
                                  if (!mounted) return;
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  ref.invalidate(
                                      vehiculoJornadaProvider(j.vehiculoId!));
                                  await _actualizar();
                                } on TransportQueued catch (e) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())));
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    update(() => enviando = false);
                                  }
                                  if (mounted) _error(e);
                                }
                              },
                        child: Text(enviando
                            ? 'Guardando...'
                            : 'Guardar Observación (continuar jornada)'))
                  ],
                )));
  }

  void _error(Object e) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo completar la operación: $e')));
}

class _Evento {
  const _Evento(
      this.fecha, this.titulo, this.descripcion, this.foto, this.color);
  final DateTime? fecha;
  final String titulo;
  final String descripcion;
  final String? foto;
  final String color;
}

String _resumen(JornadaTransporte a) {
  if (a.detallesCombustible case final c?) {
    return 'Abastecimiento: ${c['galones']} gal · S/ ${c['costo'] ?? "Sin costo registrado"} · Vale ${c['comprobante'] ?? "—"}';
  }
  if (a.detallesGrua case final g?) {
    return 'Horómetro de grúa: ${g['horometro_inicial']} → ${g['horometro_final']} h';
  }
  return a.observaciones ?? 'Sin novedades';
}

String _fecha(DateTime? f) {
  if (f == null) return 'Pendiente';
  final local = _local(f);
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

DateTime _local(DateTime f) => (f.isUtc
        ? f
        : DateTime.utc(f.year, f.month, f.day, f.hour, f.minute, f.second))
    .toLocal();
