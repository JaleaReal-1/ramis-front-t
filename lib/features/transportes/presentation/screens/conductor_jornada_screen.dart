import '../widgets/observacion_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/mi_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/features/login/login_provider.dart';
import 'package:sistema_ocs/features/login/login_screen.dart';

class ConductorJornadaScreen extends ConsumerStatefulWidget {
  const ConductorJornadaScreen({super.key});

  @override
  ConsumerState<ConductorJornadaScreen> createState() =>
      _ConductorJornadaScreenState();
}

class _ConductorJornadaScreenState
    extends ConsumerState<ConductorJornadaScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0
            ? 'Seguimiento de la Jornada Actual'
            : 'Historial de jornadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content:
                      const Text('¿Estás seguro de que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).logout();
                ref.read(navigatorKeyProvider).currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const MiJornadaScreen(embedded: true),
          _AccionesRegistradasTab(
              onNewAction: () => setState(() => _selectedIndex = 0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Seguimiento'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historial'),
        ],
      ),
    );
  }
}

class _AccionesRegistradasTab extends ConsumerWidget {
  const _AccionesRegistradasTab({required this.onNewAction});

  final VoidCallback onNewAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accionesAsync = ref.watch(accionesRegistradasProvider);
    final jornadaAsync = ref.watch(miJornadaProvider);

    return accionesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudieron cargar las acciones: $error',
                  textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.spacingM),
              TextButton(
                onPressed: () => ref.invalidate(accionesRegistradasProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (acciones) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(miJornadaProvider);
          final refreshed = ref.refresh(accionesRegistradasProvider.future);
          await refreshed;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            Text('Lo que registraste', style: AppTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Consulta tus acciones y abre cada una para ver sus datos.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            if (jornadaAsync.value != null)
              _JornadaActivaCard(jornada: jornadaAsync.value!),
            if (acciones.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    const Icon(Icons.assignment_outlined,
                        size: 48, color: AppTheme.textDisabled),
                    const SizedBox(height: AppTheme.spacingM),
                    Text('Aún no tienes acciones registradas.',
                        style: AppTheme.bodyMedium),
                    const SizedBox(height: AppTheme.spacingM),
                    OutlinedButton.icon(
                      onPressed: onNewAction,
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar nueva acción'),
                    ),
                  ],
                ),
              )
            else
              ...acciones.map((accion) => _AccionTile(
                    key: ValueKey(accion.id),
                    accion: accion,
                  )),
          ],
        ),
      ),
    );
  }
}

class _JornadaActivaCard extends ConsumerWidget {
  const _JornadaActivaCard({required this.jornada});

  final JornadaTransporte jornada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: AppCard(
        backgroundColor: AppTheme.primaryLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jornada por atender', style: AppTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              jornada.accionTipo ?? 'Jornada asignada',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingM),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MiJornadaScreen(),
                  ),
                );
                ref.invalidate(miJornadaProvider);
                ref.invalidate(accionesRegistradasProvider);
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continuar jornada'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionTile extends ConsumerStatefulWidget {
  const _AccionTile({super.key, required this.accion});

  final JornadaTransporte accion;

  @override
  ConsumerState<_AccionTile> createState() => _AccionTileState();
}

class _AccionTileState extends ConsumerState<_AccionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final accion = widget.accion;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ExpansionTile(
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        leading: Icon(_iconoAccion(accion.accionTipo),
            color: colorSemaforo(accion.estadoSemaforo)),
        title: Text(accion.accionTipo ?? 'Acción #${accion.id}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_fecha(accion.fechaInicio)} · ${_estado(accion.estado)}',
          style: AppTheme.bodySmall,
        ),
        children: [
          if (_expanded) _DetalleAccion(id: accion.id),
        ],
      ),
    );
  }
}

class _DetalleAccion extends ConsumerWidget {
  const _DetalleAccion({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(detalleAccionProvider(id)).when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTheme.spacingL),
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: TextButton(
              onPressed: () => ref.invalidate(detalleAccionProvider(id)),
              child: const Text('No se pudo cargar el detalle. Reintentar'),
            ),
          ),
          data: (accion) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _dato('Vehículo', accion.vehiculoId?.toString()),
                _dato('Kilometraje inicial',
                    accion.kmInicial == null ? null : '${accion.kmInicial} km'),
                _dato(
                    'Combustible inicial',
                    accion.nivelCombustible == null
                        ? null
                        : '${accion.nivelCombustible}%'),
                _dato('Ruta', accion.ruta),
                _dato('Observaciones', accion.observaciones),
                if (accion.fotoObservacion != null)
                  FotoObservacion(url: accion.fotoObservacion!),
                _dato('Jornada principal', accion.jornadaPadreId?.toString()),
                _dato('Galones consumidos',
                    accion.galonesConsumidos?.toStringAsFixed(2)),
                _dato('Rendimiento km/gal',
                    accion.rendimientoKmGalon?.toStringAsFixed(2)),
                if (accion.detallesGrua case final detalle?) ...[
                  _dato('Actividad', detalle['actividad']?.toString()),
                  _dato('Horómetro inicial',
                      detalle['horometro_inicial']?.toString()),
                  _dato('Horómetro final',
                      detalle['horometro_final']?.toString()),
                ],
                if (accion.detallesCombustible case final detalle?) ...[
                  _dato('Galones abastecidos', detalle['galones']?.toString()),
                  _dato(
                      'Combustible final',
                      detalle['nivel_final'] == null
                          ? null
                          : "${detalle['nivel_final']}%"),
                ],
                if (accion.detallesMantenimiento case final detalle?) ...[
                  _dato('Taller', detalle['taller']?.toString()),
                  _dato('Tipo', detalle['tipo']?.toString()),
                  _dato('Trabajos',
                      (detalle['trabajos_preventivos'] as List?)?.join(', ')),
                  _dato('Descripción',
                      detalle['descripcion_correctivo']?.toString()),
                ],
                if (accion.detallesInspeccion case final detalle?) ...[
                  _dato('Fecha de inspección',
                      detalle['fecha_inspeccion']?.toString()),
                  _dato(
                      'Vencimiento', detalle['fecha_vencimiento']?.toString()),
                ],
                if (accion.detallesCocada case final detalle?)
                  _dato('Cocada', detalle['medida']?.toString()),
                if (accion.detallesTorque case final detalle?)
                  _dato('Torque', detalle['medida']?.toString()),
                if (accion.detallesTrabajosExternos case final detalle?)
                  _dato('Trabajos realizados',
                      detalle['descripcion_trabajos']?.toString()),
                if (accion.checklistFlash != null)
                  _dato(
                      'Check List Flash',
                      accion.checklistFlash!.entries
                          .where((item) => item.value == true)
                          .map((item) => item.key)
                          .join(', ')),
                if (accion.incidencias.isNotEmpty)
                  _dato(
                      'Incidencias',
                      accion.incidencias
                          .map((item) => '${item.tipo}: ${item.descripcion}')
                          .join('\n')),
              ].whereType<Widget>().toList(),
            ),
          ),
        );
  }

  Widget? _dato(String label, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.bodySmall),
          Text(value, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}

String _fecha(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}

String _estado(String estado) => switch (estado) {
      'en_curso' => 'En curso',
      'finalizada' => 'Finalizada',
      'cancelada_por_averia' => 'Cancelada por avería',
      _ => estado.replaceAll('_', ' '),
    };

IconData _iconoAccion(String? accion) => switch (accion) {
      'Empezar a Conducir' => Icons.directions_car_outlined,
      'Operar Grúa' => Icons.construction_outlined,
      'Abastecer Combustible' => Icons.local_gas_station_outlined,
      'Mantenimiento Preventivo / Correctivo' => Icons.build_outlined,
      'Reporte de Incidencias u Observaciones' => Icons.report_outlined,
      _ => Icons.assignment_outlined,
    };
