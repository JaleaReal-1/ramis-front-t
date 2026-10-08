import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/checklist_form.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/registro_accion_form.dart';

class MiJornadaScreen extends ConsumerStatefulWidget {
  const MiJornadaScreen({super.key});

  @override
  ConsumerState<MiJornadaScreen> createState() => _MiJornadaScreenState();
}

class _MiJornadaScreenState extends ConsumerState<MiJornadaScreen> {
  double? _kilometrajeBase;
  bool _loadingKm = false;

  @override
  Widget build(BuildContext context) {
    final miJornadaAsync = ref.watch(miJornadaProvider);
    final jornadaState = ref.watch(jornadaNotifierProvider);

    // Use jornadaNotifier state if it has data, otherwise use miJornadaProvider
    final JornadaTransporte? jornada = jornadaState.value?.vehiculoId != null
        ? jornadaState.value
        : miJornadaAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Jornada')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(miJornadaProvider);
        },
        child: miJornadaAsync.when(
          data: (_) => _buildBody(context, jornada),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                  const SizedBox(height: AppTheme.spacingL),
                  Text('Error: $e',
                      style:
                          AppTheme.bodyMedium.copyWith(color: AppTheme.error),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JornadaTransporte? jornada) {
    if (jornada == null) {
      return const RegistroAccionForm();
    }

    if (jornada.vehiculoId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudo identificar el vehículo de la jornada.'),
            TextButton(
              onPressed: () => ref.invalidate(miJornadaProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      children: [
        // ── Estado Card ──
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jornada #${jornada.id}', style: AppTheme.titleLarge),
                  _buildEstadoBadge(jornada.estado),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              AppInfoItem(
                icon: Icons.local_shipping,
                label: 'Vehículo ID',
                value: '${jornada.vehiculoId}',
              ),
              const SizedBox(height: AppTheme.spacingS),
              AppInfoItem(
                icon: Icons.person,
                label: 'Conductor ID',
                value: '${jornada.conductorId}',
              ),
              if (jornada.fechaInicio != null) ...[
                const SizedBox(height: AppTheme.spacingS),
                AppInfoItem(
                  icon: Icons.access_time,
                  label: 'Inicio',
                  value: _formatDate(jornada.fechaInicio!),
                ),
              ],
              if (jornada.fechaFin != null) ...[
                const SizedBox(height: AppTheme.spacingS),
                AppInfoItem(
                  icon: Icons.access_time_filled,
                  label: 'Fin',
                  value: _formatDate(jornada.fechaFin!),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingXL),

        // ── Actions based on estado ──
        if (jornada.estado == 'pendiente') ...[
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showChecklistSheet(jornada, 'inicial'),
              icon: const Icon(Icons.checklist),
              label: const Text('Checklist Inicial'),
            ),
          ),
        ],

        if (jornada.estado == 'en_curso') ...[
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showIncidenciaDialog(jornada.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
              ),
              icon: const Icon(Icons.warning_amber_outlined),
              label: const Text('Registrar Incidencia'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _showChecklistSheet(jornada, 'final'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Checklist Final'),
            ),
          ),
        ],

        if (jornada.estado == 'finalizada') ...[
          AppCard(
            backgroundColor: AppTheme.secondaryLight,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.secondary, size: 32),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Jornada finalizada exitosamente.',
                    style: AppTheme.titleMedium
                        .copyWith(color: AppTheme.secondary),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (jornada.estado == 'cancelada_por_averia') ...[
          AppCard(
            backgroundColor: const Color(0xFFFDE8E8),
            child: Row(
              children: [
                Icon(Icons.cancel, color: AppTheme.error, size: 32),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Jornada cancelada por avería detectada.',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Incidencias registradas ──
        if (jornada.incidencias.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingXL),
          Text('Incidencias Registradas', style: AppTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingS),
          ...jornada.incidencias.map((inc) => Card(
                child: ListTile(
                  leading: Icon(_getIncidenciaIcon(inc.tipo),
                      color: AppTheme.warning),
                  title:
                      Text(inc.tipo.toUpperCase(), style: AppTheme.labelLarge),
                  subtitle: Text(inc.descripcion, style: AppTheme.bodySmall),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    switch (estado) {
      case 'pendiente':
        color = AppTheme.warning;
        break;
      case 'en_curso':
        color = AppTheme.primary;
        break;
      case 'finalizada':
        color = AppTheme.secondary;
        break;
      case 'cancelada_por_averia':
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.textDisabled;
    }
    return AppBadge(text: estado.replaceAll('_', ' '), color: color);
  }

  void _showChecklistSheet(JornadaTransporte jornada, String tipo) async {
    if (jornada.vehiculoId == null) {
      ref.invalidate(miJornadaProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar el vehículo.')),
      );
      return;
    }
    // Load vehicle kilometraje
    if (_kilometrajeBase == null && !_loadingKm) {
      setState(() => _loadingKm = true);
      try {
        final repo = ref.read(transporteRepositoryProvider);
        final vehiculo = await repo.obtenerVehiculo(jornada.vehiculoId!);
        _kilometrajeBase =
            (vehiculo['kilometraje_actual'] as num?)?.toDouble() ?? 0;
      } catch (_) {
        _kilometrajeBase = 0;
      } finally {
        if (mounted) setState(() => _loadingKm = false);
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChecklistForm(
        jornadaId: jornada.id,
        tipo: tipo,
        kilometrajeBase: _kilometrajeBase ?? 0,
        onSubmit: (request) async {
          try {
            if (tipo == 'inicial') {
              await ref
                  .read(jornadaNotifierProvider.notifier)
                  .registrarChecklistInicial(jornada.id, request);
            } else {
              await ref
                  .read(jornadaNotifierProvider.notifier)
                  .registrarChecklistFinal(jornada.id, request);
            }
            if (!mounted) return;
            Navigator.pop(context);
            ref.invalidate(miJornadaProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Checklist $tipo registrado exitosamente'),
                backgroundColor: AppTheme.secondary,
              ),
            );
          } on TransportFailure catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
      ),
    );
  }

  void _showIncidenciaDialog(int jornadaId) {
    String selectedTipo = 'falla';
    final descController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar Incidencia'),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedTipo,
                  decoration: AppTheme.inputDecoration.copyWith(
                    labelText: 'Tipo de Incidencia',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'falla', child: Text('Falla')),
                    DropdownMenuItem(
                        value: 'accidente', child: Text('Accidente')),
                    DropdownMenuItem(
                        value: 'combustible', child: Text('Combustible')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedTipo = v ?? 'falla'),
                ),
                const SizedBox(height: AppTheme.spacingL),
                TextFormField(
                  controller: descController,
                  decoration: AppTheme.inputDecoration.copyWith(
                    labelText: 'Descripción',
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingrese una descripción'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!dialogFormKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(jornadaNotifierProvider.notifier)
                      .registrarIncidencia(
                        jornadaId,
                        IncidenciaRutaRequest(
                          tipo: selectedTipo,
                          descripcion: descController.text.trim(),
                        ),
                      );
                  if (!mounted) return;
                  ref.invalidate(miJornadaProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incidencia registrada'),
                      backgroundColor: AppTheme.secondary,
                    ),
                  );
                } on TransportFailure catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  IconData _getIncidenciaIcon(String tipo) {
    switch (tipo) {
      case 'falla':
        return Icons.build_outlined;
      case 'accidente':
        return Icons.car_crash_outlined;
      case 'combustible':
        return Icons.local_gas_station_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
  }
}
