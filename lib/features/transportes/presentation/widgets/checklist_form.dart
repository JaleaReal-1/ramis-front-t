import 'observacion_fields.dart';
import 'odometro_confirm.dart';
import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class ChecklistForm extends StatefulWidget {
  final int jornadaId;
  final String tipo;
  final double kilometrajeBase;
  final double? kmInicial;
  final int? nivelInicial;
  final double? capacidadTanque;
  final double galonesAbastecidos;
  final Future<void> Function(ChecklistRequest request) onSubmit;

  const ChecklistForm({
    super.key,
    required this.jornadaId,
    required this.tipo,
    required this.kilometrajeBase,
    required this.onSubmit,
    this.kmInicial,
    this.nivelInicial,
    this.capacidadTanque,
    this.galonesAbastecidos = 0,
  });

  @override
  State<ChecklistForm> createState() => _ChecklistFormState();
}

class _ChecklistFormState extends State<ChecklistForm> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _estadoGeneralController = TextEditingController();
  final _obsController = TextEditingController();

  String? _nivelCombustible;

  @override
  void initState() {
    super.initState();
    if (widget.tipo != 'final') _nivelCombustible = '75';
  }

  bool _tieneObservaciones = false;
  String _severidad = 'leve';
  String? _foto;
  List<String> _fotos = [];
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
                widget.tipo == 'final'
                    ? 'Finalizar Jornada'
                    : 'Checklist de apertura',
                style: AppTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingXL),

              if (widget.tipo == 'final') ...[
                Text(
                    'Odómetro inicial: ${widget.kmInicial ?? widget.kilometrajeBase} km'),
                Text(
                    'Combustible abastecido en ruta: ${widget.galonesAbastecidos.toStringAsFixed(2)} gal'),
                const SizedBox(height: 12),
              ],
              // Kilometraje
              TextFormField(
                onChanged: (_) => setState(() {}),
                controller: _kmController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: widget.tipo == 'final'
                      ? 'Odómetro Final (km)'
                      : 'Kilometraje Inicial',
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
                  final km = double.tryParse(v.replaceAll(',', '.'));
                  if (km == null || !km.isFinite) {
                    return 'Valor numérico inválido';
                  }
                  if (km < widget.kilometrajeBase) {
                    return 'El kilometraje no puede ser menor a ${widget.kilometrajeBase.toStringAsFixed(0)} km';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Nivel de combustible
              DropdownButtonFormField<String>(
                initialValue: _nivelCombustible,
                validator: (v) =>
                    v == null ? 'Seleccione el combustible de cierre' : null,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: widget.tipo == 'final'
                      ? 'Combustible de cierre'
                      : 'Nivel de Combustible',
                  prefixIcon: const Icon(Icons.local_gas_station),
                ),
                items: const [
                  DropdownMenuItem(value: '0', child: Text('Vacío')),
                  DropdownMenuItem(value: '25', child: Text('1/4')),
                  DropdownMenuItem(value: '50', child: Text('1/2')),
                  DropdownMenuItem(value: '75', child: Text('3/4')),
                  DropdownMenuItem(value: '100', child: Text('Lleno')),
                ],
                onChanged: (v) => setState(() => _nivelCombustible = v ?? '75'),
              ),

              const SizedBox(height: AppTheme.spacingL),

              if (widget.tipo == 'final') _resumenCierre(),
              // Estado general de apertura; el cierre usa la conformidad del checklist.
              if (widget.tipo != 'final')
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
                activeThumbColor: AppTheme.secondary,
                onChanged: (v) => setState(() => _conforme = v),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Observaciones
              ObservacionFields(
                  onPhotosChanged: (fotos) => _fotos = fotos,
                  obligatoria: !_conforme,
                  onChanged: (activa, severidad, descripcion, foto) {
                    _tieneObservaciones = activa;
                    _severidad = severidad;
                    _obsController.text = descripcion;
                    _foto = foto;
                  }),

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
                    _isSubmitting
                        ? 'Enviando...'
                        : widget.tipo == 'final'
                            ? 'Confirmar y Finalizar Jornada'
                            : 'Enviar Checklist',
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

  Widget _resumenCierre() {
    final km = double.tryParse(_kmController.text.replaceAll(',', '.'));
    final recorrido =
        km == null ? null : km - (widget.kmInicial ?? widget.kilometrajeBase);
    final nivel = double.tryParse(_nivelCombustible ?? '');
    final consumo = nivel == null ||
            widget.nivelInicial == null ||
            widget.capacidadTanque == null
        ? null
        : (widget.nivelInicial! - nivel) / 100 * widget.capacidadTanque! +
            widget.galonesAbastecidos;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              'Resumen preliminar · Recorrido: ${recorrido != null && recorrido >= 0 ? recorrido.toStringAsFixed(1) : "Pendiente"} km'),
          Text(
              'Consumo estimado: ${consumo != null && consumo >= 0 ? consumo.toStringAsFixed(2) : "Sin estimación"} gal'),
          Text(
              'Rendimiento: ${recorrido != null && recorrido >= 0 && consumo != null && consumo > 0 ? (recorrido / consumo).toStringAsFixed(2) : "Sin estimación"} km/gal'),
          if (widget.capacidadTanque == null)
            const Text(
                'La capacidad del tanque debe estar configurada para estimar el consumo.'),
        ]));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final km = double.parse(_kmController.text.trim().replaceAll(',', '.'));
    final evidencia = await confirmarOdometro(
        context, km - (widget.kmInicial ?? widget.kilometrajeBase));
    if (evidencia == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final request = ChecklistRequest(
        tieneObservaciones: _tieneObservaciones,
        severidad: _severidad,
        fotoObservacion: _foto,
        fotosObservacion: _fotos,
        odometroEvidenciaUrl: evidencia['odometro_evidencia_url'],
        odometroMotivo: evidencia['odometro_motivo'],
        tipo: widget.tipo,
        kilometraje:
            double.parse(_kmController.text.trim().replaceAll(',', '.')),
        nivelCombustible: _nivelCombustible!,
        estadoGeneral: widget.tipo == 'final'
            ? (_conforme ? 'Conforme' : 'Con observaciones')
            : _estadoGeneralController.text.trim(),
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
