import '../../providers/jornadas_provider.dart';
import '../widgets/observacion_fields.dart';
import '../widgets/transport_notification_bell.dart';
import 'conductores_screen.dart';
import 'vehiculo_detalle_screen.dart';
import '../../../dashboard/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/providers/admin_transportes_provider.dart';

class AdminTransportesScreen extends ConsumerWidget {
  const AdminTransportesScreen({super.key, this.initialIndex = 0})
      : assert(initialIndex >= 0 && initialIndex < 6);
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      initialIndex: initialIndex,
      child: Scaffold(
        drawer: CustomDrawer(
            onMenuItemTap: (_) =>
                Navigator.of(context).popUntil((route) => route.isFirst)),
        appBar: AppBar(
          title: const Text('Gestión de Flota'),
          actions: const [TransportNotificationBell()],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.assignment), text: 'Jornadas'),
              Tab(icon: Icon(Icons.local_shipping), text: 'Flota'),
              Tab(icon: Icon(Icons.visibility), text: 'Observaciones'),
              Tab(icon: Icon(Icons.build), text: 'Mantenimientos'),
              Tab(icon: Icon(Icons.gps_fixed), text: 'GPS'),
              Tab(icon: Icon(Icons.people_alt), text: 'Conductores'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _JornadasTab(),
            _FotaTab(),
            _ObservacionesTab(),
            _MantenimientosTab(),
            _GpsTab(),
            ConductoresScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

// ── Pestaña 1: Jornadas ──────────────────────────────────────────────────────
class _JornadasTab extends ConsumerWidget {
  const _JornadasTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(jornadasListProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(jornadasListProvider),
      child: jornadasAsync.when(
        data: (jornadas) {
          if (jornadas.isEmpty) {
            return const Center(child: Text('No hay jornadas registradas.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: jornadas.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                final cerradas = jornadas.where((j) =>
                    j['jornada_padre_id'] == null &&
                    j['galones_consumidos'] != null);
                final galones = cerradas.fold<double>(
                    0,
                    (total, j) =>
                        total + (j['galones_consumidos'] as num).toDouble());
                final km = cerradas.fold<double>(
                    0,
                    (total, j) =>
                        total +
                        ((j['km_final'] as num?)?.toDouble() ?? 0) -
                        ((j['km_inicial'] as num?)?.toDouble() ?? 0));
                return Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                            'Consumo consolidado: ${galones.toStringAsFixed(2)} gal · ${km.toStringAsFixed(1)} km · ${galones > 0 ? (km / galones).toStringAsFixed(2) : "Sin datos"} km/gal')));
              }
              final j = jornadas[i - 1];
              final tieneAlerta = (j['alerta_horas'] as bool? ?? false) ||
                  (j['alerta_km'] as bool? ?? false);
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: ExpansionTile(
                  leading: Icon(
                    tieneAlerta
                        ? Icons.warning_amber
                        : Icons.check_circle_outline,
                    color: colorSemaforo(
                        j['estado_semaforo'] as String? ?? 'verde'),
                  ),
                  title: Text(
                      'Jornada #${j['id']} - Conductor ID: ${j['conductor_id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Estado: ${j['estado']} | Acción: ${j['accion_tipo'] ?? 'N/A'}'),
                      if (tieneAlerta)
                        Text(
                          '⚠ Tiene alertas de horas/km',
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.error),
                        ),
                    ],
                  ),
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Vehículo #${j['vehiculo_id']} · Jornada principal: ${j['jornada_padre_id'] ?? j['id']}'),
                              Text(j['observaciones'] as String? ??
                                  'Sin novedades'),
                              if (j['foto_observacion'] != null)
                                FotoObservacion(
                                    url: j['foto_observacion'] as String),
                              Text(
                                  'Km efectivos: ${j['km_final'] != null && j['km_inicial'] != null ? (j['km_final'] as num) - (j['km_inicial'] as num) : 'Pendiente'}'),
                              Text(
                                  'Consumo: ${j['galones_consumidos'] ?? 'Sin datos de tanque/cierre'} gal · Rendimiento: ${j['rendimiento_km_galon'] ?? 'Pendiente'} km/gal'),
                            ])),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Pestaña 2: Flota ─────────────────────────────────────────────────────────
class _FotaTab extends ConsumerWidget {
  const _FotaTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiculosAsync = ref.watch(vehiculosListProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(vehiculosListProvider),
      child: vehiculosAsync.when(
        data: (vehiculos) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: vehiculos.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(spacing: 16, children: [
                          FilledButton.icon(
                              onPressed: () => mostrarAltaVehiculo(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Alta Rápida de Vehículo')),
                          if (vehiculos.isEmpty)
                            const Text('No hay vehículos registrados.'),
                          for (final estado in ['verde', 'amarillo', 'rojo'])
                            Chip(
                                avatar: Icon(Icons.circle,
                                    color: colorSemaforo(estado), size: 16),
                                label: Text(
                                    '$estado: ${vehiculos.where((v) => (v['estado_semaforo'] ?? 'verde') == estado).length}')),
                        ])));
              }
              final v = vehiculos[i - 1];
              final estado = v['estado'] as String? ?? 'desconocido';
              final color = switch (estado) {
                'disponible' => AppTheme.secondary,
                'en_ruta' => AppTheme.primary,
                'en_mantenimiento' => AppTheme.warning,
                _ => AppTheme.textDisabled,
              };
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(30),
                    child: Icon(Icons.directions_car,
                        color: colorSemaforo(
                            v['estado_semaforo'] as String? ?? 'verde')),
                  ),
                  onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VehiculoDetalleScreen(vehiculo: v))),
                  title: Text('${v['placa']} - ${v['marca']} ${v['modelo']}'),
                  subtitle:
                      Text('Km: ${v['kilometraje_actual']} | Estado: $estado'),
                  trailing: PopupMenuButton<String>(
                      tooltip: 'Opciones del vehículo',
                      onSelected: (_) => _editarVehiculo(context, ref, v),
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'tanque',
                                child: Text('Configurar tipo y tanque'))
                          ]),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Pestaña 3: Observaciones ─────────────────────────────────────────────────
class _ObservacionesTab extends ConsumerWidget {
  const _ObservacionesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(jornadasListProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(jornadasListProvider),
      child: jornadasAsync.when(
        data: (jornadas) {
          final conObs = jornadas
              .where((j) =>
                  j['observaciones'] != null &&
                  (j['observaciones'] as String).isNotEmpty &&
                  j['observaciones'] != 'Sin novedades')
              .toList();
          if (conObs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_off_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay observaciones registradas.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: conObs.length,
            itemBuilder: (_, i) {
              final j = conObs[i];
              return Card(
                  child: ExpansionTile(
                leading: Icon(Icons.circle,
                    color: colorSemaforo(
                        j['estado_semaforo'] as String? ?? 'verde')),
                title:
                    Text('Jornada #${j['id']} · Vehículo #${j['vehiculo_id']}'),
                subtitle: Text(j['accion_tipo'] as String? ?? 'Jornada'),
                children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text(j['observaciones'] as String),
                        if (j['foto_observacion'] != null)
                          FotoObservacion(url: j['foto_observacion'] as String),
                      ]))
                ],
              ));
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Pestaña 4: Mantenimientos ────────────────────────────────────────────────
class _MantenimientosTab extends ConsumerWidget {
  const _MantenimientosTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantenimientosAsync = ref.watch(mantenimientosListProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(mantenimientosListProvider),
      child: mantenimientosAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
                child: Text('No hay mantenimientos registrados.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final m = items[i];
              final estado = m['estado'] as String? ?? 'pendiente';
              final colorEstado = switch (estado.toLowerCase()) {
                'finalizado' || 'completado' => AppTheme.secondary,
                'en_proceso' || 'en proceso' => AppTheme.primary,
                _ => AppTheme.warning,
              };
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.build_circle)),
                  title: Text(m['descripcion'] as String? ?? 'Mantenimiento'),
                  subtitle: Text(
                      'Vehículo ID: ${m['vehiculo_id']} | Tipo: ${m['tipo'] ?? 'N/A'}'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorEstado.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(estado,
                        style: AppTheme.bodySmall.copyWith(color: colorEstado)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Pestaña 5: GPS ───────────────────────────────────────────────────────────
class _GpsTab extends StatelessWidget {
  const _GpsTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gps_fixed, size: 80, color: AppTheme.textDisabled),
          const SizedBox(height: 16),
          Text('Integración futura de GPS',
              style:
                  AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Este módulo permitirá el rastreo en tiempo real\nde los vehículos de la flota.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textDisabled),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Helper widget compartido ──────────────────────────────────────────────────
// ignore: unused_element
Widget _buildList(
  AsyncValue<List<Map<String, dynamic>>> asyncData,
  Widget Function(Map<String, dynamic> item) builder, {
  Future<void> Function()? onRefresh,
}) {
  return asyncData.when(
    data: (items) {
      if (items.isEmpty) {
        return const Center(child: Text('Sin datos disponibles.'));
      }
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => builder(items[i]),
        ),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text('Error: $e')),
  );
}

Future<void> _editarVehiculo(
    BuildContext context, WidgetRef ref, Map<String, dynamic> vehiculo) async {
  const tipos = ['Camión Grúa', 'Camión de Carga', 'Camioneta', 'Coaster'];
  String tipo = tipos.contains(vehiculo['tipo'])
      ? vehiculo['tipo'] as String
      : 'Camión de Carga';
  final capacidad = TextEditingController(
      text: vehiculo['capacidad_tanque_galones']?.toString() ?? '');
  final form = GlobalKey<FormState>();
  bool guardando = false;
  await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => AlertDialog(
                scrollable: true,
                title: Text('Datos de ${vehiculo['placa']}'),
                content: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButtonFormField<String>(
                          initialValue: tipo,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Tipo de vehículo'),
                          items: tipos
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => tipo = v!),
                      TextFormField(
                          controller: capacidad,
                          decoration: const InputDecoration(
                              labelText: 'Capacidad del tanque (galones)',
                              helperText:
                                  'Necesaria para estimar el consumo por jornada',
                              helperMaxLines: 2),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) => (v ?? '').isNotEmpty &&
                                  (double.tryParse(v!.replaceAll(',', '.')) ==
                                          null ||
                                      double.parse(v.replaceAll(',', '.')) <= 0)
                              ? 'Ingrese una capacidad mayor a cero'
                              : null),
                    ])),
                actions: [
                  TextButton(
                      onPressed: guardando ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: guardando
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              update(() => guardando = true);
                              try {
                                await ref
                                    .read(transporteRepositoryProvider)
                                    .actualizarDatosVehiculo(
                                        vehiculo['id'] as int,
                                        tipo,
                                        double.tryParse(capacidad.text
                                            .replaceAll(',', '.')));
                                ref.invalidate(vehiculosListProvider);
                                ref.invalidate(vehiculosDisponiblesProvider);
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                if (ctx.mounted) {
                                  update(() => guardando = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('No se pudo guardar: $e')));
                                }
                              }
                            },
                      child: Text(guardando ? 'Guardando...' : 'Guardar'))
                ],
              )));
  capacidad.dispose();
}
