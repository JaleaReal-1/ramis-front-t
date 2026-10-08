import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/fuel_gauge_selector.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/dynamic_actions/grua_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/dynamic_actions/combustible_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/dynamic_actions/mantenimiento_form_widget.dart';

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
    "Ruta Juliaca a Arequipa (Viceversa)",
    "Otras"
  ];

  final Map<String, bool> _checklistFlash = {
    "Documentos en vigencia (Soat, Rev.Tec., Tarjeta propiedad, licencia)":
        false,
    "Linterna (deberá estar en la guantera)": false,
    "Kits de herramientas (gata, cable pasacorriente, triangulo, alicate y desarmadores)":
        false,
    "Botiquín": false,
    "Llanta de repuesto": false,
    "Extintor": false,
    "Tacos": false,
    "Conos": false,
    "Lampa y pico": false,
    "Kits antiderrames": false,
    "Codificación": false,
  };

  String? _accionSeleccionada;
  int? _vehiculoId;
  String? _rutaSeleccionada;
  double _nivelCombustible = 100;
  final _observacionesController = TextEditingController();
  final _otraRutaController = TextEditingController();
  final _kmController = TextEditingController();
  bool _loadingKm = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    _otraRutaController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _fetchKilometraje(int? vehiculoId) async {
    _kmController.clear();
    if (vehiculoId == null) return;
    setState(() => _loadingKm = true);
    try {
      final repo = ref.read(transporteRepositoryProvider);
      final km = await repo.obtenerKilometrajeVehiculo(vehiculoId);
      if (mounted && _vehiculoId == vehiculoId) {
        _kmController.text = km.toStringAsFixed(1);
      }
    } catch (_) {
      // El campo queda vacío y su validador impide enviar datos incompletos.
    } finally {
      if (mounted && _vehiculoId == vehiculoId) {
        setState(() => _loadingKm = false);
      }
    }
  }

  AccionGruaRequest? _detallesGrua;
  AccionCombustibleRequest? _detallesCombustible;
  AccionMantenimientoRequest? _detallesMantenimiento;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: AppCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Registro de Actividad', style: AppTheme.titleLarge),
              const SizedBox(height: AppTheme.spacingL),
              _buildGlobalFields(),
              const SizedBox(height: AppTheme.spacingL),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'ACCIÓN A REALIZAR',
                  prefixIcon: const Icon(Icons.touch_app),
                ),
                items: _acciones
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setState(() {
                  _accionSeleccionada = val;
                  _detallesGrua = null;
                  _detallesCombustible = null;
                  _detallesMantenimiento = null;
                }),
                validator: (val) =>
                    val == null ? 'Seleccione una acción' : null,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              if (_accionSeleccionada == "Empezar a Conducir") ...[
                _buildConducirFields(),
              ] else if (_accionSeleccionada == "Operar Grúa") ...[
                GruaFormWidget(
                    onChanged: (val) => setState(() => _detallesGrua = val)),
              ] else if (_accionSeleccionada == "Abastecer Combustible") ...[
                CombustibleFormWidget(
                    onChanged: (val) =>
                        setState(() => _detallesCombustible = val)),
              ] else if (_accionSeleccionada ==
                  "Mantenimiento Preventivo / Correctivo") ...[
                Material(
                  type: MaterialType.transparency,
                  child: MantenimientoFormWidget(
                      onChanged: (val) =>
                          setState(() => _detallesMantenimiento = val)),
                ),
              ] else if (_accionSeleccionada != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.construction,
                          size: 48, color: AppTheme.textDisabled),
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
              const SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: _observacionesController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'Observaciones (Opcional)',
                  alignLabelWithHint: true,
                  helperText:
                      'Informar si hay alguna condición para revisar y/o reparar, reponer, implementar u oportunidades de mejora',
                  helperMaxLines: 5,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppTheme.spacingXL),
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
                      _isSubmitting ? 'Registrando...' : 'Registrar Acción'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalFields() {
    final vehiculosAsync = ref.watch(vehiculosDisponiblesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Vehículo ──
        vehiculosAsync.when(
          data: (vehiculos) {
            final disponibles =
                vehiculos.where((v) => v['estado'] == 'disponible').toList();
            return DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Vehículo',
                prefixIcon: const Icon(Icons.local_shipping_outlined),
              ),
              items: disponibles
                  .map((v) => DropdownMenuItem<int>(
                        value: v['id'] as int,
                        child: Text(
                          '${v['placa']} - ${v['marca']} ${v['modelo']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => _vehiculoId = val);
                _fetchKilometraje(val);
              },
              validator: (val) => val == null ? 'Seleccione un vehículo' : null,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error al cargar vehículos: $e',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
        ),
        const SizedBox(height: AppTheme.spacingL),

        // ── Kilometraje Inicial ──
        TextFormField(
          controller: _kmController,
          readOnly: true,
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: 'Kilometraje Inicial',
            prefixIcon: const Icon(Icons.speed),
            helperText: 'Km registrado del vehículo al inicio',
            suffixIcon: _loadingKm
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) => value == null || value.isEmpty
              ? 'Espere a que se cargue el kilometraje'
              : null,
        ),
        const SizedBox(height: AppTheme.spacingL),

        // ── Combustible Inicial ──
        FuelGaugeSelector(
          value: _nivelCombustible.toInt(),
          onChanged: (val) =>
              setState(() => _nivelCombustible = val.toDouble()),
        ),
      ],
    );
  }

  Widget _buildConducirFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Ruta ──
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: 'Ruta o Recorrido',
            prefixIcon: const Icon(Icons.route),
          ),
          items: _rutas
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _rutaSeleccionada = val),
          validator: (val) => val == null ? 'Seleccione una ruta' : null,
        ),
        if (_rutaSeleccionada == 'Otras') ...[
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _otraRutaController,
            decoration: AppTheme.inputDecoration.copyWith(
              labelText: 'Especifique la ruta',
              prefixIcon: const Icon(Icons.edit_road),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingrese la ruta o recorrido'
                : null,
          ),
        ],
        const SizedBox(height: AppTheme.spacingL),

        // ── Check List Flash ──
        Text('Check List Flash (Obligatorio)',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppTheme.spacingS),
        Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _checklistFlash.keys.map((item) {
              return CheckboxListTile(
                title: Text(item, style: AppTheme.bodySmall, softWrap: true),
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
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_vehiculoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un vehículo.')),
      );
      return;
    }

    // Validate that all checklist items are true only if we are driving
    if (_accionSeleccionada == "Empezar a Conducir" &&
        _checklistFlash.values.any((v) => !v)) {
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
              ruta: _accionSeleccionada == 'Empezar a Conducir'
                  ? (_rutaSeleccionada == 'Otras'
                      ? _otraRutaController.text.trim()
                      : _rutaSeleccionada)
                  : null,
              nivelCombustible: _nivelCombustible.toInt(),
              checklistFlash: _accionSeleccionada == 'Empezar a Conducir'
                  ? _checklistFlash
                  : null,
              observaciones: _observacionesController.text,
              detallesGrua: _detallesGrua,
              detallesCombustible: _detallesCombustible,
              detallesMantenimiento: _detallesMantenimiento,
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
