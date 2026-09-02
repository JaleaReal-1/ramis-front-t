import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/features/transportes/models/vehiculo_model.dart';
import 'package:sistema_ocs/features/transportes/providers/transportes_provider.dart';
import 'package:sistema_ocs/features/transportes/screens/transportes_operacion_screens.dart';

/// Pantalla de detalle e historial de un vehiculo.
class VehiculoDetalleScreen extends ConsumerWidget {
  const VehiculoDetalleScreen({
    super.key,
    required this.vehiculoId,
    this.role = 'admin',
  });

  final int vehiculoId;
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiculoState = ref.watch(vehiculoProvider(vehiculoId));
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial del vehiculo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mantenimientos'),
              Tab(text: 'Inspecciones'),
              Tab(text: 'Averias'),
              Tab(text: 'Incidentes'),
            ],
          ),
        ),
        body: vehiculoState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (vehiculo) => _VehiculoDetalleBody(
            vehiculo: vehiculo,
            role: role,
          ),
        ),
      ),
    );
  }
}

class _VehiculoDetalleBody extends ConsumerWidget {
  const _VehiculoDetalleBody({required this.vehiculo, required this.role});

  final VehiculoModel vehiculo;
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _header(context, ref),
        Expanded(
          child: TabBarView(
            children: [
              _mantenimientos(context, ref),
              _inspecciones(context, ref),
              _averias(context, ref),
              _incidentes(context, ref),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vehiculo.placa} - ${vehiculo.marca} ${vehiculo.modelo}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('Estado: ${vehiculo.estado}')),
              if (vehiculo.kilometrajeActual != null)
                Chip(
                  label: Text(
                    'Km: ${vehiculo.kilometrajeActual!.toStringAsFixed(0)}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.fact_check, size: 18),
                label: const Text('Checklist salida'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspeccionScreen(
                        vehiculoId: vehiculo.id,
                        trabajadorId: 0,
                        tipo: TipoInspeccion.salida,
                        kilometrajeInicial: vehiculo.kilometrajeActual,
                      ),
                    ),
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Checklist llegada'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspeccionScreen(
                        vehiculoId: vehiculo.id,
                        trabajadorId: 0,
                        tipo: TipoInspeccion.llegada,
                        kilometrajeInicial: vehiculo.kilometrajeActual,
                      ),
                    ),
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.build, size: 18),
                label: const Text('Reportar averia'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AveriaFormScreen(
                        vehiculoId: vehiculo.id,
                      ),
                    ),
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.report, size: 18),
                label: const Text('Reportar incidente'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IncidenteFormScreen(
                        vehiculoId: vehiculo.id,
                        trabajadorId: 0,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mantenimientos(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mantenimientosVehiculoProvider(vehiculo.id));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (items) => items.isEmpty
          ? const Center(child: Text('Sin mantenimientos'))
          : ListView(
              children: [
                for (final item in items)
                  ListTile(
                    leading: const Icon(Icons.build),
                    title: Text(item.descripcion),
                    subtitle: Text(
                      '${item.tipoMantenimiento} | '
                      '${item.estadoMantenimiento} | '
                      'S/ ${item.costo.toStringAsFixed(2)}',
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _inspecciones(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspeccionesVehiculoProvider(vehiculo.id));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (items) => items.isEmpty
          ? const Center(child: Text('Sin inspecciones'))
          : ListView(
              children: [
                for (final item in items)
                  ListTile(
                    leading: const Icon(Icons.fact_check),
                    title: Text(item.tipo),
                    subtitle: Text('${item.fecha} | ${item.resultado}'),
                  ),
              ],
            ),
    );
  }

  Widget _averias(BuildContext context, WidgetRef ref) {
    final state = ref.watch(averiasVehiculoProvider(vehiculo.id));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (items) => items.isEmpty
          ? const Center(child: Text('Sin averias'))
          : ListView(
              children: [
                for (final item in items)
                  ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: Text('${item.categoria} - ${item.componente}'),
                    subtitle: Text('${item.criticidad} | ${item.estado}'),
                  ),
              ],
            ),
    );
  }

  Widget _incidentes(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentesVehiculoProvider(vehiculo.id));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (items) => items.isEmpty
          ? const Center(child: Text('Sin incidentes'))
          : ListView(
              children: [
                for (final item in items)
                  ListTile(
                    leading: const Icon(Icons.car_crash),
                    title: Text(item.tipo),
                    subtitle: Text(
                      '${item.fecha} | ${item.estado} | ${item.ubicacion}',
                    ),
                  ),
              ],
            ),
    );
  }
}

