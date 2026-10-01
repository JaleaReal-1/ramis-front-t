import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class ChecklistForm extends StatefulWidget {
  final int jornadaId;
  final String tipo;
  final double kilometrajeBase;
  final Future<void> Function(ChecklistRequest request) onSubmit;

  const ChecklistForm({
    super.key,
    required this.jornadaId,
    required this.tipo,
    required this.kilometrajeBase,
    required this.onSubmit,
  });

  @override
  State<ChecklistForm> createState() => _ChecklistFormState();
}

class _ChecklistFormState extends State<ChecklistForm> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _estadoGeneralController = TextEditingController();
  final _obsController = TextEditingController();

  String _nivelCombustible = '3/4';
  bool _conforme = true;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        top: AppTheme.spacingL,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: AppTheme.borderRadiusCircle,
                  ),
                ),
              ),

              Text(
                'Checklist ${widget.tipo.toUpperCase()}',
                style: AppTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // Kilometraje
              TextFormField(
                controller: _kmController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'Kilometraje',
                  suffixText: 'km',
                  prefixIcon: const Icon(Icons.speed),
                  helperText:
                      'Kilometraje actual: ${widget.kilometrajeBase.toStringAsFixed(0)} km',
                  helperStyle:
                      AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingrese el kilometraje';
                  }
                  final km = double.tryParse(v);
                  if (km == null) return 'Valor numérico inválido';
                  if (km < widget.kilometrajeBase) {
                    return 'El kilometraje no puede ser menor a ${widget.kilometrajeBase.toStringAsFixed(0)} km';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Nivel de combustible
              DropdownButtonFormField<String>(
                value: _nivelCombustible,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'Nivel de Combustible',
                  prefixIcon: const Icon(Icons.local_gas_station),
                ),
                items: const [
                  DropdownMenuItem(value: '1/4', child: Text('1/4')),
                  DropdownMenuItem(value: '1/2', child: Text('1/2')),
                  DropdownMenuItem(value: '3/4', child: Text('3/4')),
                  DropdownMenuItem(value: 'Lleno', child: Text('Lleno')),
                ],
                onChanged: (v) =>
                    setState(() => _nivelCombustible = v ?? '3/4'),
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Estado general
              TextFormField(
                controller: _estadoGeneralController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'Estado General del Vehículo',
                  prefixIcon: const Icon(Icons.car_repair),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingrese el estado general'
                    : null,
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Conforme switch
              SwitchListTile(
                title: Text('Conforme', style: AppTheme.titleSmall),
                subtitle: Text(
                  _conforme
                      ? 'El vehículo está en buenas condiciones'
                      : 'Se detectaron problemas',
                  style: AppTheme.bodySmall,
                ),
                value: _conforme,
                activeColor: AppTheme.secondary,
                onChanged: (v) => setState(() => _conforme = v),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Observaciones
              TextFormField(
                controller: _obsController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'Observaciones (opcional)',
                  prefixIcon: const Icon(Icons.notes),
                ),
                maxLines: 3,
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
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting ? 'Enviando...' : 'Enviar Checklist',
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final request = ChecklistRequest(
        tipo: widget.tipo,
        kilometraje: double.parse(_kmController.text.trim()),
        nivelCombustible: _nivelCombustible,
        estadoGeneral: _estadoGeneralController.text.trim(),
        conforme: _conforme,
        observaciones: _obsController.text.trim().isEmpty
            ? null
            : _obsController.text.trim(),
      );
      await widget.onSubmit(request);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    _estadoGeneralController.dispose();
    _obsController.dispose();
    super.dispose();
  }
}
