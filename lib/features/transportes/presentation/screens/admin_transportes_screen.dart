import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/providers/admin_transportes_provider.dart';

class AdminTransportesScreen extends ConsumerWidget {
  const AdminTransportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Flota'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.local_shipping), text: 'Vehículos'),
              Tab(icon: Icon(Icons.build), text: 'Mantenimientos'),
              Tab(icon: Icon(Icons.warning), text: 'Averías / Incidentes'),
              Tab(icon: Icon(Icons.map), text: 'Rutas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _VehiculosTab(),
            _MantenimientosTab(),
            _AveriasIncidentesTab(),
            _RutasTab(),
          ],
        ),
      ),
    );
  }
}

class _VehiculosTab extends ConsumerWidget {
  const _VehiculosTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(vehiculosListProvider);
    return _buildList(
      asyncData,
      (item) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.directions_car)),
        title: Text('${item['placa']} - ${item['marca']} ${item['modelo']}'),
        subtitle: Text('Estado: ${item['estado']} | Km: ${item['kilometraje_actual']}'),
        trailing: const Icon(Icons.chevron_right),
      ),
      onRefresh: () async => ref.invalidate(vehiculosListProvider),
    );
  }
}

class _MantenimientosTab extends ConsumerWidget {
  const _MantenimientosTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(mantenimientosListProvider);
    return _buildList(
      asyncData,
      (item) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.handyman)),
        title: Text('${item['tipo']} - Vehículo ID: ${item['vehiculo_id']}'),
        subtitle: Text('Estado: ${item['estado']} | Costo: \$${item['costo'] ?? 0}'),
        trailing: const Icon(Icons.chevron_right),
      ),
      onRefresh: () async => ref.invalidate(mantenimientosListProvider),
    );
  }
}

class _AveriasIncidentesTab extends ConsumerWidget {
  const _AveriasIncidentesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(averiasListProvider);
    return _buildList(
      asyncData,
      (item) => ListTile(
        leading: const CircleAvatar(backgroundColor: AppTheme.error, child: Icon(Icons.broken_image, color: Colors.white)),
        title: Text('Avería: ${item['descripcion']}'),
        subtitle: Text('Gravedad: ${item['gravedad']} | Estado: ${item['estado']}'),
      ),
      onRefresh: () async => ref.invalidate(averiasListProvider),
    );
  }
}

class _RutasTab extends ConsumerWidget {
  const _RutasTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(rutasListProvider);
    return _buildList(
      asyncData,
      (item) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.route)),
        title: Text('Ruta ID: ${item['id']} - Vehículo ID: ${item['vehiculo_id']}'),
        subtitle: Text('Estado: ${item['estado']} | Fecha: ${item['fecha_inicio'] ?? 'Pendiente'}'),
      ),
      onRefresh: () async => ref.invalidate(rutasListProvider),
    );
  }
}

Widget _buildList(
  AsyncValue<List<Map<String, dynamic>>> asyncData,
  Widget Function(Map<String, dynamic>) itemBuilder, {
  required Future<void> Function() onRefresh,
}) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: asyncData.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No hay registros encontrados.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error al cargar datos: $err', style: AppTheme.bodyMedium.copyWith(color: AppTheme.error)),
      ),
    ),
  );
}
