import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sistema_ocs/features/transportes/models/mantenimiento_model.dart';
import 'package:sistema_ocs/features/transportes/models/ruta_asignacion_model.dart';
import 'package:sistema_ocs/features/transportes/models/vehiculo_model.dart';
import 'package:sistema_ocs/features/transportes/providers/transportes_provider.dart';
import 'package:sistema_ocs/features/transportes/screens/transportes_forms.dart';
import 'package:sistema_ocs/features/transportes/screens/transportes_historial_screen.dart';
import 'package:sistema_ocs/features/transportes/screens/transportes_operacion_screens.dart';

class TransportesHomeScreen extends StatelessWidget {
  const TransportesHomeScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: const FlutterSecureStorage().read(key: 'user_role'),
      builder: (context, snapshot) {
        final currentRole = snapshot.data ?? role;
        final canManage = currentRole == 'admin' || currentRole == 'almacenero';
        return DefaultTabController(
          length: canManage ? 3 : 1,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  if (canManage)
                    const Tab(
                      icon: Icon(Icons.local_shipping),
                      text: 'Vehiculos',
                    ),
                  const Tab(icon: Icon(Icons.route), text: 'Rutas'),
                  if (canManage)
                    const Tab(icon: Icon(Icons.build), text: 'Mantenimientos'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    if (canManage) VehiculosScreen(role: currentRole),
                    RutasScreen(role: currentRole),
                    if (canManage) MantenimientosScreen(role: currentRole),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VehiculosScreen extends ConsumerWidget {
  const VehiculosScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehiculosProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(vehiculosProvider)),
      data: (vehicles) => _ResourceList<VehiculoModel>(
        emptyMessage: 'No hay vehiculos activos',
        onRefresh: () => ref.refresh(vehiculosProvider.future),
        floatingActionButton: role == 'almacenero'
            ? FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehiculoFormScreen()),
                ),
                child: const Icon(Icons.add),
              )
            : null,
        items: vehicles,
        itemBuilder: (vehicle) => ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehiculoDetalleScreen(
                vehiculoId: vehicle.id,
                role: role,
              ),
            ),
          ),
          leading: const Icon(Icons.local_shipping),
          title: Text('${vehicle.placa} - ${vehicle.marca} ${vehicle.modelo}'),
          subtitle: Text('${vehicle.capacidadCarga} t'),
          trailing: role == 'almacenero'
              ? PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'historial') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehiculoDetalleScreen(
                            vehiculoId: vehicle.id,
                            role: role,
                          ),
                        ),
                      );
                    } else if (action == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehiculoFormScreen(vehicle: vehicle),
                        ),
                      );
                    } else if (action == 'delete') {
                      await _deleteResource(
                        context,
                        'Desactivar vehiculo',
                        () => ref
                            .read(transportesServiceProvider)
                            .eliminarVehiculo(vehicle.id),
                        () => ref.invalidate(vehiculosProvider),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'historial', child: Text('Historial')),
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Desactivar')),
                  ],
                )
              : Chip(label: Text(vehicle.estado)),
        ),
      ),
    );
  }
}

class RutasScreen extends ConsumerWidget {
  const RutasScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rutasProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(rutasProvider)),
      data: (routes) => _ResourceList<RutaAsignacionModel>(
        emptyMessage: 'No hay rutas activas',
        onRefresh: () => ref.refresh(rutasProvider.future),
        floatingActionButton: role == 'admin' || role == 'almacenero'
            ? FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RutaFormScreen()),
                ),
                child: const Icon(Icons.add),
              )
            : null,
        items: routes,
        itemBuilder: (route) => ListTile(
          leading: const Icon(Icons.route),
          title: Text('${route.origen} - ${route.destino}'),
          subtitle: Text(
              'Vehiculo ${route.vehiculoId} | Trabajador ${route.trabajadorId}'),
          trailing: Wrap(
            spacing: 4,
            children: [
              Chip(label: Text(route.estadoRuta)),
              if (role == 'trabajador' && route.estadoRuta == 'pendiente')
                IconButton(
                  tooltip: 'Iniciar ruta',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IniciarRutaScreen(route: route),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                ),
              if ((role == 'trabajador' ||
                      role == 'admin' ||
                      role == 'almacenero') &&
                  route.estadoRuta == 'en_progreso')
                IconButton(
                  tooltip: 'Finalizar ruta',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FinalizarRutaScreen(route: route),
                    ),
                  ),
                  icon: const Icon(Icons.stop),
                ),
              if (role == 'admin' || role == 'almacenero')
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'delete') {
                      await _deleteResource(
                        context,
                        'Desactivar ruta',
                        () => ref
                            .read(transportesServiceProvider)
                            .eliminarRuta(route.id),
                        () => ref.invalidate(rutasProvider),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Desactivar')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MantenimientosScreen extends ConsumerWidget {
  const MantenimientosScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mantenimientosProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(mantenimientosProvider)),
      data: (maintenance) => _ResourceList<MantenimientoListModel>(
        emptyMessage: 'No hay mantenimientos activos',
        onRefresh: () => ref.refresh(mantenimientosProvider.future),
        floatingActionButton: role == 'admin' || role == 'almacenero'
            ? FloatingActionButton(
                onPressed: () => _selectVehicleForMaintenance(context, ref),
                child: const Icon(Icons.add),
              )
            : null,
        items: maintenance,
        itemBuilder: (item) => ListTile(
          leading: const Icon(Icons.build),
          title: Text(item.descripcion),
          subtitle: Text(
              'Vehiculo ${item.vehiculoId} | '
              '${item.tipoMantenimiento} | S/ ${item.costo.toStringAsFixed(2)}'),
          trailing: role == 'admin' || role == 'almacenero'
              ? Wrap(
                  children: [
                    Chip(label: Text(item.estadoMantenimiento)),
                    if (item.estadoEjecucion == 'pendiente')
                      IconButton(
                        tooltip: 'Ejecutar mantenimiento',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EjecutarMantenimientoScreen(
                              mantenimientoId: item.id,
                              vehiculoId: item.vehiculoId,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.play_circle),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'ejecutar' &&
                            item.estadoEjecucion == 'pendiente') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EjecutarMantenimientoScreen(
                                mantenimientoId: item.id,
                                vehiculoId: item.vehiculoId,
                              ),
                            ),
                          );
                        } else if (action == 'delete') {
                          await _deleteResource(
                            context,
                            'Desactivar mantenimiento',
                            () => ref
                                .read(transportesServiceProvider)
                                .eliminarMantenimiento(item.id),
                            () => ref.invalidate(mantenimientosProvider),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        if (item.estadoEjecucion == 'pendiente')
                          const PopupMenuItem(
                            value: 'ejecutar',
                            child: Text('Ejecutar'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Desactivar'),
                        ),
                      ],
                    ),
                  ],
                )
              : Chip(label: Text(item.estadoMantenimiento)),
        ),
      ),
    );
  }
}

class _ResourceList<T> extends StatelessWidget {
  const _ResourceList({
    required this.items,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.onRefresh,
    this.floatingActionButton,
  });

  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Scaffold(
        floatingActionButton: floatingActionButton,
        body: Center(child: Text(emptyMessage)),
      );
    }
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) => itemBuilder(items[index]),
        ),
      ),
    );
  }
}

Future<void> _selectVehicleForMaintenance(
  BuildContext context,
  WidgetRef ref,
) async {
  final vehicles = await ref.read(vehiculosProvider.future);
  if (!context.mounted || vehicles.isEmpty) return;
  final vehicleId = await showDialog<int>(
    context: context,
    builder: (_) => SimpleDialog(
      title: const Text('Seleccione un vehículo'),
      children: [
        for (final vehicle in vehicles)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, vehicle.id),
            child: Text('${vehicle.placa} (${vehicle.estado})'),
          ),
      ],
    ),
  );
  if (vehicleId != null && context.mounted) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MantenimientoFormScreen(vehicleId: vehicleId),
      ),
    );
  }
}

Future<void> _deleteResource(
  BuildContext context,
  String title,
  Future<void> Function() action,
  VoidCallback invalidate,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: const Text('El registro pasará a estado inactivo.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await action();
    invalidate();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
