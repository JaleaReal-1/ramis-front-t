import '../widgets/vehiculo_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

class AsignacionJornadaScreen extends ConsumerStatefulWidget {
  const AsignacionJornadaScreen({super.key});

  @override
  ConsumerState<AsignacionJornadaScreen> createState() =>
      _AsignacionJornadaScreenState();
}

class _AsignacionJornadaScreenState
    extends ConsumerState<AsignacionJornadaScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedVehiculoId;
  int? _selectedConductorId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Forzar refresco de datos cada vez que se abre la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(vehiculosDisponiblesProvider);
      ref.invalidate(trabajadoresProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiculosAsync = ref.watch(vehiculosDisponiblesProvider);
    final trabajadoresAsync = ref.watch(trabajadoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Jornada')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nueva Jornada de Transporte',
                        style: AppTheme.titleLarge),
                    const SizedBox(height: AppTheme.spacingXL),

                    // ── Vehículo ──
                    vehiculosAsync.when(
                      data: (vehiculos) {
                        return VehiculoSelector(
                            vehiculos: vehiculos,
                            value: _selectedVehiculoId,
                            onChanged: (v) => setState(
                                () => _selectedVehiculoId = v['id'] as int));
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(
                        'Error al cargar vehículos: $e',
                        style:
                            AppTheme.bodySmall.copyWith(color: AppTheme.error),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingL),

                    // ── Conductor ──
                    trabajadoresAsync.when(
                      data: (trabajadores) {
                        return DropdownButtonFormField<int>(
                          decoration: AppTheme.inputDecoration.copyWith(
                            labelText: 'Conductor',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          items: trabajadores
                              .map((t) => DropdownMenuItem<int>(
                                    value: t['id'] as int,
                                    child: Text(
                                      '${t['nombre']} ${t['apellidos'] ?? ''}'
                                          .trim(),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedConductorId = val),
                          validator: (val) =>
                              val == null ? 'Seleccione un conductor' : null,
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(
                        'Error al cargar trabajadores: $e',
                        style:
                            AppTheme.bodySmall.copyWith(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textOnPrimary,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSubmitting ? 'Asignando...' : 'Crear Jornada',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehiculoId == null || _selectedConductorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Por favor seleccione un vehículo y un conductor válidos.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(jornadaNotifierProvider.notifier).asignar(
            AsignarJornadaRequest(
              vehiculoId: _selectedVehiculoId!,
              conductorId: _selectedConductorId!,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jornada asignada exitosamente'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      Navigator.pop(context);
    } on TransportFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
