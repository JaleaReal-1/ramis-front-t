// lib/features/requerimientos/rqs_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/rq_model.dart';
import 'package:sistema_ocs/features/requerimientos/rq_providers.dart';
import 'package:sistema_ocs/features/requerimientos/rq_detail_screen.dart';

class RQsListScreen extends ConsumerWidget {
  const RQsListScreen({super.key});

  void _handleDelete(
      BuildContext context, WidgetRef ref, int rqId, String nroRq) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        // Cambiado a Dialog estándar para mejor control de tamaño
        backgroundColor: Colors.transparent,
        child: AppCard(
          backgroundColor: AppTheme.background,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirmar Eliminación',
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  '¿Está seguro de eliminar el Requerimiento $nroRq? Esta acción es irreversible.',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingM),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.borderRadiusMedium,
                          ),
                          side: BorderSide(color: AppTheme.border),
                        ),
                        child: Text(
                          'Cancelar',
                          style: AppTheme.labelLarge
                              .copyWith(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: AppButton(
                        text: 'Eliminar',
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          try {
                            await ref
                                .read(rqListNotifierProvider.notifier)
                                .deleteRq(rqId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('RQ $nroRq eliminado con éxito.'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppTheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        backgroundColor: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rqsAsyncValue = ref.watch(rqListNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background, // Usamos color sólido o gradiente del tema
      ),
      child: Column(
        children: [
          // Header con búsqueda mejorado para evitar overflow
          AppCard(
            backgroundColor: AppTheme.background,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.border.withOpacity(0.3),
                        borderRadius: AppTheme.borderRadiusMedium,
                      ),
                      child: TextField(
                        style: AppTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Buscar RQ...',
                          hintStyle: AppTheme.bodySmall
                              .copyWith(color: AppTheme.textDisabled),
                          border: InputBorder.none,
                          icon: Icon(Icons.search,
                              color: AppTheme.primary, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Material(
                    color: AppTheme.primary,
                    borderRadius: AppTheme.borderRadiusMedium,
                    child: IconButton(
                      icon: Icon(Icons.refresh, color: AppTheme.background),
                      onPressed: () => ref.invalidate(rqListNotifierProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de RQs
          Expanded(
            child: rqsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error al cargar datos')),
              data: (rqs) {
                if (rqs.isEmpty) {
                  return const Center(
                      child: Text('No hay requerimientos disponibles'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  itemCount: rqs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: RQCard(
                        rq: rqs[index],
                        onDelete: () => _handleDelete(
                            context, ref, rqs[index].id, rqs[index].nroRq),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RQCard extends StatelessWidget {
  final RQResponse rq;
  final VoidCallback onDelete;

  const RQCard({super.key, required this.rq, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(rq.estado);
    final progressColor = AppTheme.getProgressColor(rq.progresoCompra);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Nro y Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rq.nroRq,
                        style: AppTheme.titleLarge
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Emisión: ${rq.fechaEmision.toLocal().toString().split(' ')[0]}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textDisabled),
                      ),
                    ],
                  ),
                ),
                AppBadge(text: rq.estado, color: statusColor),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Info items con Wrap o Expanded para evitar desbordamientos laterales
            Row(
              children: [
                Expanded(
                  child: AppInfoItem(
                    icon: Icons.person_outline,
                    label: 'Solicitante',
                    value: rq.solicitante,
                    iconColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: AppInfoItem(
                    icon: Icons.work_outline,
                    label: 'Proyecto',
                    value: rq.proyecto,
                    iconColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Divider(),

            // Progreso
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progreso de Compra', style: AppTheme.labelMedium),
                      Text('${rq.progresoCompra.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: progressColor,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  AppProgressBar(progress: rq.progresoCompra),
                ],
              ),
            ),

            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Flexible(
                  child: AppButton(
                    text: 'Ver Detalles',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RQDetailScreen(rq: rq),
                        ),
                      );
                    },
                    icon: Icons.visibility_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
