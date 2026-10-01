import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

class RegistroAccionForm extends ConsumerStatefulWidget {
  const RegistroAccionForm({super.key});

  @override
  ConsumerState<RegistroAccionForm> createState() => _RegistroAccionFormState();
}

class _RegistroAccionFormState extends ConsumerState<RegistroAccionForm> {
  final _formKey = GlobalKey<FormState>();
  
  static const _acciones = [
    "Empezar a Conducir",
    "Operar Grúa",
    "Abastecer Combustible",
    "Mantenimiento Preventivo / Correctivo",
    "Reporte de Incidencias u Observaciones",
    "Check List y/o V°B° de vehículos",
    "Inspección Técnica",
    "Medición de Cocada",
    "Medición de Torque",
    "Trabajos a Externos",
  ];

  static const _rutas = [
    "Traslados en la UM San Rafael",
    "Traslados sólo en Antauta",
    "Traslados en Juliaca",
    "Ruta Antauta a Juliaca (Viceversa)",
    "Otras"
  ];

  final Map<String, bool> _checklistFlash = {
    "Documentos": false,
    "Linterna": false,
    "Kits herramientas": false,
    "Botiquín": false,
    "Llanta repuesto": false,
    "Extintor": false,
    "Tacos": false,
    "Conos": false,
    "Lampa/pico": false,
    "Kits antiderrames": false,
    "Codificación": false,
  };

  String? _accionSeleccionada;
  int? _vehiculoId;
  String? _rutaSeleccionada;
  double _nivelCombustible = 100;
  final _observacionesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Registro de Actividad', style: AppTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingL),
            DropdownButtonFormField<String>(
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'ACCIÓN A REALIZAR',
                prefixIcon: const Icon(Icons.touch_app),
              ),
              items: _acciones
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (val) => setState(() {
                _accionSeleccionada = val;
                // Reset form state if needed
              }),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            if (_accionSeleccionada == "Empezar a Conducir") ...[
              _buildConducirForm(),
            ] else if (_accionSeleccionada != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.construction, size: 48, color: AppTheme.textDisabled),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Formulario en construcción para esta acción.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConducirForm() {
    final vehiculosAsync = ref.watch(vehiculosDisponiblesProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Vehículo ──
          vehiculosAsync.when(
            data: (vehiculos) {
              final disponibles =
                  vehiculos.where((v) => v['estado'] == 'disponible').toList();
              return DropdownButtonFormField<int>(
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'Vehículo a Conducir',
                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                ),
                items: disponibles
                    .map((v) => DropdownMenuItem<int>(
                          value: v['id'] as int,
                          child: Text(
                              '${v['placa']} - ${v['marca']} ${v['modelo']}'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _vehiculoId = val),
                validator: (val) =>
                    val == null ? 'Seleccione un vehículo' : null,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error al cargar vehículos: $e',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // ── Ruta ──
          DropdownButtonFormField<String>(
            decoration: AppTheme.inputDecoration.copyWith(
              labelText: 'Ruta o Recorrido',
              prefixIcon: const Icon(Icons.route),
            ),
            items: _rutas
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (val) => setState(() => _rutaSeleccionada = val),
            validator: (val) => val == null ? 'Seleccione una ruta' : null,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // ── Nivel de Combustible ──
          Text('Nivel de Combustible: ${_nivelCombustible.toInt()}%',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          Slider(
            value: _nivelCombustible,
            min: 0,
            max: 100,
            divisions: 4,
            label: '${_nivelCombustible.toInt()}%',
            onChanged: (val) => setState(() => _nivelCombustible = val),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // ── Check List Flash ──
          Text('Check List Flash (Obligatorio)',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacingS),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _checklistFlash.keys.map((item) {
                return CheckboxListTile(
                  title: Text(item, style: AppTheme.bodySmall),
                  value: _checklistFlash[item],
                  onChanged: (val) {
                    setState(() {
                      _checklistFlash[item] = val ?? false;
                    });
                  },
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // ── Observaciones ──
          TextFormField(
            controller: _observacionesController,
            decoration: AppTheme.inputDecoration.copyWith(
              labelText: 'Observaciones (Opcional)',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // ── Submit ──
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
                  : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Registrando...' : 'Registrar Acción'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate that all checklist items are true
    if (_checklistFlash.values.any((v) => !v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe confirmar todos los ítems del Check List Flash.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(jornadaNotifierProvider.notifier).registrarAccion(
            RegistroAccionRequest(
              accionTipo: _accionSeleccionada!,
              vehiculoId: _vehiculoId,
              ruta: _rutaSeleccionada,
              nivelCombustible: _nivelCombustible.toInt(),
              checklistFlash: _checklistFlash,
              observaciones: _observacionesController.text,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acción registrada exitosamente'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      // Trigger a refresh of the miJornadaProvider
      ref.invalidate(miJornadaProvider);
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
