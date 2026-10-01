import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/providers/admin_transportes_provider.dart';

class AdminTransportesScreen extends ConsumerWidget {
  const AdminTransportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Flota'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.assignment), text: 'Jornadas'),
              Tab(icon: Icon(Icons.local_shipping), text: 'Flota'),
              Tab(icon: Icon(Icons.visibility), text: 'Observaciones'),
              Tab(icon: Icon(Icons.build), text: 'Mantenimientos'),
              Tab(icon: Icon(Icons.gps_fixed), text: 'GPS'),
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
            itemCount: jornadas.length,
            itemBuilder: (_, i) {
              final j = jornadas[i];
              final tieneAlerta =
                  (j['alerta_horas'] as bool? ?? false) ||
                  (j['alerta_km'] as bool? ?? false);
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: ListTile(
                  leading: Icon(
                    tieneAlerta ? Icons.warning_amber : Icons.check_circle_outline,
                    color: tieneAlerta ? AppTheme.warning : AppTheme.secondary,
                  ),
                  title: Text('Jornada #${j['id']} - Conductor ID: ${j['conductor_id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado: ${j['estado']} | Acción: ${j['accion_tipo'] ?? 'N/A'}'),
                      if (tieneAlerta)
                        Text(
                          '⚠ Tiene alertas de horas/km',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
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
          if (vehiculos.isEmpty) {
            return const Center(child: Text('No hay vehículos registrados.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: vehiculos.length,
            itemBuilder: (_, i) {
              final v = vehiculos[i];
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
                    child: Icon(Icons.directions_car, color: color),
                  ),
                  title: Text('${v['placa']} - ${v['marca']} ${v['modelo']}'),
                  subtitle: Text('Km: ${v['kilometraje_actual']} | Estado: $estado'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(estado,
                        style: AppTheme.bodySmall.copyWith(color: color)),
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
                  (j['observaciones'] as String).isNotEmpty)
              .toList();
          if (conObs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_off_outlined, size: 64, color: Colors.grey),
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
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jornada #${j['id']} — Conductor #${j['conductor_id']}',
                        style: AppTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(j['observaciones'] as String, style: AppTheme.bodySmall),
                    if (j['accion_tipo'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Acción: ${j['accion_tipo']}',
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.textSecondary)),
                    ],
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
            return const Center(child: Text('No hay mantenimientos registrados.'));
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
                        style:
                            AppTheme.bodySmall.copyWith(color: colorEstado)),
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
              style: AppTheme.titleMedium
                  .copyWith(color: AppTheme.textSecondary)),
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
