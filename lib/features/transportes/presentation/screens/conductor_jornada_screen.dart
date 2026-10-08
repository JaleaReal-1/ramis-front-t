import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/registro_accion_form.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

/// Pantalla contenedora del rol Conductor con BottomNavigationBar.
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
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _JornadaActivaTab(),
          _HistorialTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Jornada Activa',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Jornada Activa ────────────────────────────────────────────────────

class _JornadaActivaTab extends ConsumerWidget {
  const _JornadaActivaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reutiliza el MiJornadaScreen que ya existe y contiene el formulario dinámico
    return const _MiJornadaWrapper();
  }
}

class _MiJornadaWrapper extends ConsumerWidget {
  const _MiJornadaWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Import inline para evitar import circular
    // La pantalla MiJornadaScreen ya maneja todo el flujo
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Jornada'),
        automaticallyImplyLeading: false,
      ),
      body: Builder(
        builder: (ctx) {
          // Delegamos directamente al contenido de MiJornadaScreen
          // embebiendo su lógica de body aquí
          return const _JornadaBody();
        },
      ),
    );
  }
}

class _JornadaBody extends ConsumerWidget {
  const _JornadaBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miJornadaAsync = ref.watch(miJornadaProvider);
    final jornadaState = ref.watch(jornadaNotifierProvider);
    final JornadaTransporte? jornada =
        jornadaState.value ?? miJornadaAsync.value;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(miJornadaProvider),
      child: miJornadaAsync.when(
        data: (_) {
          if (jornada == null) {
            // Sin jornada activa: mostrar el formulario para registrar acción
            return const RegistroAccionForm();
          }
          // Jornada activa: muestra info básica
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jornada #${jornada.id}',
                            style: AppTheme.titleLarge),
                        _estadoBadge(jornada.estado),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    if (jornada.accionTipo != null)
                      Text(jornada.accionTipo!,
                          style: AppTheme.bodyMedium
                              .copyWith(color: AppTheme.textSecondary)),
                    if (jornada.ruta != null) ...[
                      const SizedBox(height: AppTheme.spacingS),
                      Row(
                        children: [
                          const Icon(Icons.route, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(jornada.ruta!,
                                  style: AppTheme.bodySmall)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.error)),
        ),
      ),
    );
  }

  Widget _estadoBadge(String estado) {
    final color = switch (estado) {
      'en_curso' => AppTheme.primary,
      'finalizada' => AppTheme.secondary,
      'cancelada_por_averia' => AppTheme.error,
      _ => AppTheme.textDisabled,
    };
    return AppBadge(text: estado.replaceAll('_', ' '), color: color);
  }
}

// ── Tab 2: Historial ─────────────────────────────────────────────────────────

class _HistorialTab extends ConsumerWidget {
  const _HistorialTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialConductorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Historial'),
        automaticallyImplyLeading: false,
      ),
      body: historialAsync.when(
        data: (jornadas) {
          if (jornadas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes jornadas finalizadas aún.'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(historialConductorProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: jornadas.length,
              itemBuilder: (ctx, i) => _JornadaHistorialTile(jornada: jornadas[i]),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _JornadaHistorialTile extends StatelessWidget {
  const _JornadaHistorialTile({required this.jornada});
  final JornadaTransporte jornada;

  @override
  Widget build(BuildContext context) {
    final kmRecorridos = (jornada.kmFinal != null && jornada.kmInicial != null)
        ? (jornada.kmFinal! - jornada.kmInicial!).toStringAsFixed(1)
        : '--';
    final horas = jornada.horasEfectivas?.toStringAsFixed(1) ?? '--';
    final tieneAlertas = (jornada.alertaHoras || jornada.alertaKm);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ExpansionTile(
        leading: Icon(
          tieneAlertas ? Icons.warning_amber : Icons.check_circle_outline,
          color: tieneAlertas ? AppTheme.warning : AppTheme.secondary,
        ),
        title: Text(
          'Jornada #${jornada.id} - ${jornada.accionTipo ?? 'Conducción'}',
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          jornada.fechaFin != null
              ? _formatDate(jornada.fechaFin!)
              : 'Sin fecha de cierre',
          style: AppTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _InfoRow(icon: Icons.timer, label: 'Horas Efectivas', value: '$horas h'),
                _InfoRow(icon: Icons.speed, label: 'Km Recorridos', value: '$kmRecorridos km'),
                if (jornada.ruta != null)
                  _InfoRow(icon: Icons.route, label: 'Ruta', value: jornada.ruta!),
                if (jornada.alertaHoras) ...[
                  const SizedBox(height: 8),
                  _AlertaBanner(
                    text: '⚠ Alerta: Jornada superó 10 horas efectivas',
                    color: AppTheme.error,
                  ),
                ],
                if (jornada.alertaKm) ...[
                  const SizedBox(height: 4),
                  _AlertaBanner(
                    text: '⚠ Alerta: Kilometraje recorrido excede 200 km',
                    color: Colors.orange,
                  ),
                ],
                if (jornada.incidencias.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Incidencias (${jornada.incidencias.length})',
                      style: AppTheme.labelLarge),
                  ...jornada.incidencias.map((inc) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• ${inc.tipo}: ${inc.descripcion}',
                        style: AppTheme.bodySmall),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          Expanded(child: Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _AlertaBanner extends StatelessWidget {
  const _AlertaBanner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(text,
          style: AppTheme.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
