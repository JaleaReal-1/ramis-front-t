import 'vehiculo_selector.dart';
import 'observacion_fields.dart';
import 'odometro_confirm.dart';
import '../../data/repositories/transporte_repository_impl.dart';
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
import 'package:sistema_ocs/features/transportes/presentation/widgets/inspeccion_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/cocada_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/torque_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/trabajos_externos_form_widget.dart';

class RegistroAccionForm extends ConsumerStatefulWidget {
  const RegistroAccionForm(
      {super.key, this.onRegistered, this.jornada, this.soloApertura = false});

  final JornadaTransporte? jornada;
  final bool soloApertura;

  final VoidCallback? onRegistered;

  @override
  ConsumerState<RegistroAccionForm> createState() => _RegistroAccionFormState();
}

class _RegistroAccionFormState extends ConsumerState<RegistroAccionForm> {
  final _formKey = GlobalKey<FormState>();
  final _fechaRegistro = DateTime.now();

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

  final Map<String, List<String>> _categorias = {
    'Fluidos y Motor': [
      'Nivel de aceite',
      'Nivel de refrigerante',
      'Líquido de frenos',
      'Ausencia de fugas visibles'
    ],
    'Sistema Eléctrico y Luces': [
      'Faros principales',
      'Direccionales e intermitentes',
      'Bocina',
      'Luces de frenado y reversa'
    ],
    'Neumáticos y Ruedas': [
      'Presión de llantas',
      'Cocada visible segura',
      'Tuercas completas'
    ],
  };
  @override
  void initState() {
    super.initState();
    _vehiculoId = widget.jornada?.vehiculoId;
    _nivelCombustible = widget.jornada?.nivelCombustible;
    if (widget.soloApertura) _accionSeleccionada = "Empezar a Conducir";
    for (final items in _categorias.values) {
      for (final item in items) {
        _checklistFlash[item] = false;
      }
    }
  }

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
  int? _nivelCombustible;
  final _observacionesController = TextEditingController();
  final _otraRutaController = TextEditingController();
  final _kmController = TextEditingController();
  bool _loadingKm = false;
  bool _isSubmitting = false;
  bool _tieneObservaciones = false;
  String _severidad = 'leve';
  String? _foto;
  List<String> _fotos = [];
  double _kmBase = 0;
  bool _esGrua = false;
  bool _esLigero = false;

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
      _kmBase = km;
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
  AccionInspeccionRequest? _detallesInspeccion;
  AccionCocadaRequest? _detallesCocada;
  AccionTorqueRequest? _detallesTorque;
  AccionTrabajosExternosRequest? _detallesTrabajosExternos;

  @override
  Widget build(BuildContext context) {
    final vehiculos = ref.watch(vehiculosDisponiblesProvider).value ?? [];
    final actual = vehiculos.where((v) => v['id'] == _vehiculoId);
    if (actual.isNotEmpty) {
      final v = actual.first;
      final tipo = (v['tipo'] ?? v['modelo'] ?? '').toString().toLowerCase();
      _esLigero = ['camioneta', 'coaster'].contains(tipo);
      _esGrua = tipo.contains('grúa') ||
          tipo.contains('grua') ||
          (v['tipo'] == null && ['Z7F-777', 'Z7M-813'].contains(v['placa']));
    }
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
                key: ValueKey("$_vehiculoId-$_esGrua"),
                initialValue: _accionSeleccionada,
                items: _acciones
                    .where((a) => widget.soloApertura
                        ? a == 'Empezar a Conducir'
                        : widget.jornada != null
                            ? a != 'Empezar a Conducir'
                            : true)
                    .where((a) =>
                        (a != "Operar Grúa" || _esGrua) &&
                        (!_esLigero ||
                            ![
                              "Medición de Cocada",
                              "Medición de Torque",
                              "Trabajos a Externos"
                            ].contains(a)))
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
                  _detallesInspeccion = null;
                  _detallesCocada = null;
                  _detallesTorque = null;
                  _detallesTrabajosExternos = null;
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
              ] else if (_accionSeleccionada ==
                  "Check List y/o V°B° de vehículos") ...[
                _buildChecklistFlash(),
              ] else if (_accionSeleccionada == "Inspección Técnica") ...[
                InspeccionFormWidget(
                  onChanged: (value) =>
                      setState(() => _detallesInspeccion = value),
                ),
              ] else if (_accionSeleccionada == "Medición de Cocada") ...[
                CocadaFormWidget(
                  onChanged: (value) => setState(() => _detallesCocada = value),
                ),
              ] else if (_accionSeleccionada == "Medición de Torque") ...[
                TorqueFormWidget(
                  onChanged: (value) => setState(() => _detallesTorque = value),
                ),
              ] else if (_accionSeleccionada == "Trabajos a Externos") ...[
                TrabajosExternosFormWidget(
                  onChanged: (value) =>
                      setState(() => _detallesTrabajosExternos = value),
                ),
              ],
              const SizedBox(height: AppTheme.spacingL),
              ObservacionFields(
                onPhotosChanged: (fotos) => _fotos = fotos,
                obligatoria: _accionSeleccionada ==
                    'Reporte de Incidencias u Observaciones',
                onChanged: (activa, severidad, descripcion, foto) {
                  _tieneObservaciones = activa;
                  _severidad = severidad;
                  _observacionesController.text = descripcion;
                  _foto = foto;
                },
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
    final usuarioAsync = ref.watch(currentUserForTransportProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildReadonlyField(
          'Fecha del Registro',
          Icons.calendar_today_outlined,
          '${_fechaRegistro.day.toString().padLeft(2, '0')}/'
              '${_fechaRegistro.month.toString().padLeft(2, '0')}/'
              '${_fechaRegistro.year} '
              '${_fechaRegistro.hour.toString().padLeft(2, '0')}:'
              '${_fechaRegistro.minute.toString().padLeft(2, '0')}',
        ),
        const SizedBox(height: AppTheme.spacingL),
        usuarioAsync.when(
          data: (usuario) => _buildReadonlyField(
            'Nombre del Registrador',
            Icons.person_outline,
            usuario == null
                ? 'Usuario no disponible'
                : '${usuario.nombre} ${usuario.apellidos}'.trim(),
          ),
          loading: () => _buildReadonlyField(
            'Nombre del Registrador',
            Icons.person_outline,
            'Cargando...',
          ),
          error: (_, __) => _buildReadonlyField(
            'Nombre del Registrador',
            Icons.person_outline,
            'Usuario no disponible',
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // ── Vehículo ──
        vehiculosAsync.when(
          data: (vehiculos) {
            if (widget.jornada != null) {
              final lista = vehiculos.where((v) => v['id'] == _vehiculoId);
              final vehiculo = lista.isEmpty ? null : lista.first;
              return _buildReadonlyField(
                  'Vehículo de la jornada',
                  Icons.local_shipping,
                  vehiculo == null
                      ? 'Vehículo #$_vehiculoId'
                      : '${vehiculo['placa']} · ${vehiculo['tipo'] ?? vehiculo['modelo']}');
            }
            return VehiculoSelector(
              vehiculos: vehiculos,
              value: _vehiculoId,
              onChanged: (v) {
                setState(() {
                  _vehiculoId = v['id'] as int;
                  _accionSeleccionada =
                      widget.soloApertura ? 'Empezar a Conducir' : null;
                });
                _fetchKilometraje(_vehiculoId);
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error al cargar vehículos: $e',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
        ),
        const SizedBox(height: AppTheme.spacingL),

        if (_accionSeleccionada != 'Operar Grúa') ...[
          // ── Kilometraje Inicial ──
          TextFormField(
            controller: _kmController,
            decoration: AppTheme.inputDecoration.copyWith(
              labelText: widget.jornada == null
                  ? 'Kilometraje Inicial'
                  : 'Odómetro al registrar la actividad',
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
            validator: (value) {
              final kmStr = value?.replaceAll(',', '.') ?? '';
              final km = double.tryParse(kmStr);
              return km == null || km <= 0
                  ? 'El kilometraje inicial debe ser mayor que cero'
                  : null;
            },
          ),
          const SizedBox(height: AppTheme.spacingL),

          // ── Combustible Inicial ──
          FormField<int>(
            initialValue: _nivelCombustible,
            validator: (value) => value == null
                ? 'Seleccione el nivel de combustible inicial'
                : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FuelGaugeSelector(
                  value: _nivelCombustible,
                  onChanged: (value) {
                    field.didChange(value);
                    setState(() => _nivelCombustible = value);
                  },
                ),
                if (field.hasError)
                  Text(field.errorText!,
                      style:
                          AppTheme.bodySmall.copyWith(color: AppTheme.error)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReadonlyField(String label, IconData icon, String value) {
    return InputDecorator(
      decoration: AppTheme.inputDecoration.copyWith(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: Text(value, style: AppTheme.bodyMedium),
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
        _buildChecklistFlash(),
      ],
    );
  }

  Widget _buildChecklistFlash() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Check List Flash (Obligatorio)',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        if (_checklistFlash.entries.any((e) =>
            !e.value &&
            RegExp('freno|direcci|Extintor|Documentos', caseSensitive: false)
                .hasMatch(e.key)))
          const Card(
              color: Color(0xFFFFF3CD),
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                      'Advertencia de seguridad: revise frenos/dirección, extintor y documentos. Se notificará a administración; la supervisión debe evaluar la operación.'))),
        const SizedBox(height: AppTheme.spacingS),
        Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final categoria in {
                ..._categorias,
                'Seguridad y Documentos': _checklistFlash.keys
                    .where((k) =>
                        !_categorias.values.any((items) => items.contains(k)))
                    .toList()
              }.entries) ...[
                const Divider(),
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(categoria.key, style: AppTheme.labelLarge)),
                for (final item in categoria.value)
                  CheckboxListTile(
                      title:
                          Text(item, style: AppTheme.bodySmall, softWrap: true),
                      value: _checklistFlash[item],
                      onChanged: (v) =>
                          setState(() => _checklistFlash[item] = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (ref.read(currentUserForTransportProvider).value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al registrador.')),
      );
      return;
    }

    if (_vehiculoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un vehículo.')),
      );
      return;
    }

    final distancia = _accionSeleccionada == 'Operar Grúa'
        ? 0.0
        : (double.tryParse(_kmController.text.replaceAll(',', '.')) ??
                _kmBase) -
            _kmBase;
    final evidencia = await confirmarOdometro(context, distancia);
    if (evidencia == null || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(jornadaNotifierProvider.notifier).registrarAccion(
            RegistroAccionRequest(
              accionTipo: _accionSeleccionada!,
              vehiculoId: _vehiculoId!,
              jornadaPadreId: widget.jornada?.id,
              kmInicial: _accionSeleccionada == 'Operar Grúa'
                  ? null
                  : double.parse(_kmController.text.replaceAll(',', '.')),
              ruta: _accionSeleccionada == 'Empezar a Conducir'
                  ? (_rutaSeleccionada == 'Otras'
                      ? _otraRutaController.text.trim()
                      : _rutaSeleccionada)
                  : null,
              nivelCombustible: _accionSeleccionada == 'Operar Grúa'
                  ? null
                  : _nivelCombustible!,
              checklistFlash: _accionSeleccionada == 'Empezar a Conducir' ||
                      _accionSeleccionada == 'Check List y/o V°B° de vehículos'
                  ? _checklistFlash
                  : null,
              tieneObservaciones: _tieneObservaciones,
              severidad: _severidad,
              fotoObservacion: _foto,
              fotosObservacion: _fotos,
              odometroEvidenciaUrl: evidencia['odometro_evidencia_url'],
              odometroMotivo: evidencia['odometro_motivo'],
              observaciones: _tieneObservaciones
                  ? _observacionesController.text.trim()
                  : 'Sin novedades',
              detallesGrua: _detallesGrua,
              detallesCombustible: _detallesCombustible,
              detallesMantenimiento: _detallesMantenimiento,
              detallesInspeccion: _detallesInspeccion,
              detallesCocada: _detallesCocada,
              detallesTorque: _detallesTorque,
              detallesTrabajosExternos: _detallesTrabajosExternos,
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
      ref.invalidate(vehiculosDisponiblesProvider);
      ref.invalidate(miJornadaProvider);
      ref.invalidate(accionesRegistradasProvider);
      widget.onRegistered?.call();
    } on TransportQueued catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      widget.onRegistered?.call();
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
