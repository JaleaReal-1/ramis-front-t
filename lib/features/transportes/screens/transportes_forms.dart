import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:sistema_ocs/features/transportes/models/averia_model.dart';
import 'package:sistema_ocs/features/transportes/models/mantenimiento_model.dart';
import 'package:sistema_ocs/features/transportes/models/ruta_asignacion_model.dart';
import 'package:sistema_ocs/features/transportes/models/vehiculo_model.dart';
import 'package:sistema_ocs/features/transportes/providers/transportes_provider.dart';

class FirmaTrabajadorScreen extends StatefulWidget {
  const FirmaTrabajadorScreen({super.key});

  @override
  State<FirmaTrabajadorScreen> createState() => _FirmaTrabajadorScreenState();
}

class _FirmaTrabajadorScreenState extends State<FirmaTrabajadorScreen> {
  final _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Future<void> _confirmar() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe firmar antes de continuar')),
      );
      return;
    }
    final image = await _controller.toImage();
    final data = await image?.toByteData(format: ui.ImageByteFormat.png);
    if (data == null || !mounted) return;
    Navigator.pop(context, base64Encode(data.buffer.asUint8List()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma del trabajador'),
        actions: [
          IconButton(
            tooltip: 'Limpiar firma',
            onPressed: _controller.clear,
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirmar,
                icon: const Icon(Icons.check),
                label: const Text('Usar firma'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VehiculoFormScreen extends ConsumerStatefulWidget {
  const VehiculoFormScreen({super.key, this.vehicle});

  final VehiculoModel? vehicle;

  @override
  ConsumerState<VehiculoFormScreen> createState() => _VehiculoFormScreenState();
}

class _VehiculoFormScreenState extends ConsumerState<VehiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _placa;
  late final TextEditingController _marca;
  late final TextEditingController _modelo;
  late final TextEditingController _capacidad;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _placa = TextEditingController(text: vehicle?.placa);
    _marca = TextEditingController(text: vehicle?.marca);
    _modelo = TextEditingController(text: vehicle?.modelo);
    _capacidad =
        TextEditingController(text: vehicle?.capacidadCarga.toString());
  }

  @override
  void dispose() {
    _placa.dispose();
    _marca.dispose();
    _modelo.dispose();
    _capacidad.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final service = ref.read(transportesServiceProvider);
    try {
      if (widget.vehicle == null) {
        await service.crearVehiculo(CrearVehiculoRequest(
          placa: _placa.text.trim(),
          marca: _marca.text.trim(),
          modelo: _modelo.text.trim(),
          capacidadCarga: double.parse(_capacidad.text.trim()),
        ));
      } else {
        await service.actualizarVehiculo(
          widget.vehicle!.id,
          ActualizarVehiculoRequest(
            placa: _placa.text.trim(),
            marca: _marca.text.trim(),
            modelo: _modelo.text.trim(),
            capacidadCarga: double.parse(_capacidad.text.trim()),
          ),
        );
      }
      ref.invalidate(vehiculosProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.vehicle == null ? 'Nuevo vehículo' : 'Editar vehículo',
      formKey: _formKey,
      saving: _saving,
      onSubmit: _save,
      children: [
        _field(_placa, 'Placa'),
        _field(_marca, 'Marca'),
        _field(_modelo, 'Modelo'),
        _field(_capacidad, 'Capacidad de carga', number: true),
      ],
    );
  }
}

class RutaFormScreen extends ConsumerStatefulWidget {
  const RutaFormScreen({super.key});

  @override
  ConsumerState<RutaFormScreen> createState() => _RutaFormScreenState();
}

class _RutaFormScreenState extends ConsumerState<RutaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicle = TextEditingController();
  final _worker = TextEditingController();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _departure = TextEditingController(text: _isoDate());
  final _arrival = TextEditingController(text: _isoDate(hours: 4));
  bool _saving = false;

  static String _isoDate({int hours = 0}) =>
      DateTime.now().add(Duration(hours: hours)).toIso8601String();

  @override
  void dispose() {
    for (final controller in [
      _vehicle,
      _worker,
      _origin,
      _destination,
      _departure,
      _arrival,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(transportesServiceProvider).crearRuta(CrearRutaRequest(
            vehiculoId: int.parse(_vehicle.text),
            trabajadorId: int.parse(_worker.text),
            origen: _origin.text.trim(),
            destino: _destination.text.trim(),
            fechaSalida: DateTime.parse(_departure.text.trim()),
            fechaLlegadaEstimada: DateTime.parse(_arrival.text.trim()),
          ));
      ref.invalidate(rutasProvider);
      ref.invalidate(vehiculosProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Nueva ruta',
      formKey: _formKey,
      saving: _saving,
      onSubmit: _save,
      children: [
        _field(_vehicle, 'ID del vehículo', number: true),
        _field(_worker, 'ID del trabajador', number: true),
        _field(_origin, 'Origen'),
        _field(_destination, 'Destino'),
        _field(_departure, 'Salida (ISO 8601)'),
        _field(_arrival, 'Llegada estimada (ISO 8601)'),
      ],
    );
  }
}

class IniciarRutaScreen extends ConsumerStatefulWidget {
  const IniciarRutaScreen({super.key, required this.route});

  final RutaAsignacionModel route;

  @override
  ConsumerState<IniciarRutaScreen> createState() => _IniciarRutaScreenState();
}

class _IniciarRutaScreenState extends ConsumerState<IniciarRutaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kilometraje = TextEditingController();
  final _combustible = TextEditingController(text: 'lleno');
  String? _firma;
  bool _llantas = false;
  bool _frenos = false;
  bool _luces = false;
  bool _saving = false;

  Future<void> _firmar() async {
    final signature = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FirmaTrabajadorScreen()),
    );
    if (signature != null) setState(() => _firma = signature);
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate() ||
        _firma == null ||
        !_llantas ||
        !_frenos ||
        !_luces) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete la firma y los tres checks')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(transportesServiceProvider).iniciarRuta(
            widget.route.id,
            IniciarRutaRequest(
              firmaTrabajador: _firma!,
              checkLlantas: _llantas,
              checkFrenos: _frenos,
              checkLuces: _luces,
              kilometrajeSalida: double.parse(_kilometraje.text),
              combustibleSalida: _combustible.text.trim(),
            ),
          );
      ref.invalidate(rutasProvider);
      ref.invalidate(vehiculosProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _kilometraje.dispose();
    _combustible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Iniciar ruta',
      formKey: _formKey,
      saving: _saving,
      onSubmit: _start,
      submitLabel: 'Iniciar ruta',
      children: [
        Text('Ruta: ${widget.route.origen} - ${widget.route.destino}'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _firmar,
          icon: Icon(_firma == null ? Icons.draw : Icons.check),
          label: Text(_firma == null ? 'Firmar' : 'Firma registrada'),
        ),
        CheckboxListTile(
            value: _llantas,
            onChanged: (v) => setState(() => _llantas = v ?? false),
            title: const Text('Llantas verificadas')),
        CheckboxListTile(
            value: _frenos,
            onChanged: (v) => setState(() => _frenos = v ?? false),
            title: const Text('Frenos verificados')),
        CheckboxListTile(
            value: _luces,
            onChanged: (v) => setState(() => _luces = v ?? false),
            title: const Text('Luces verificadas')),
        _field(_kilometraje, 'Kilometraje de salida', number: true),
        _field(_combustible, 'Combustible de salida'),
      ],
    );
  }
}

class FinalizarRutaScreen extends ConsumerStatefulWidget {
  const FinalizarRutaScreen({super.key, required this.route});

  final RutaAsignacionModel route;

  @override
  ConsumerState<FinalizarRutaScreen> createState() =>
      _FinalizarRutaScreenState();
}

class _FinalizarRutaScreenState extends ConsumerState<FinalizarRutaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kilometraje = TextEditingController();
  final _combustible = TextEditingController(text: 'lleno');
  final _observaciones = TextEditingController(text: 'Llegada sin novedades');
  bool _saving = false;

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(transportesServiceProvider).finalizarRuta(
            widget.route.id,
            FinalizarRutaRequest(
              kilometrajeLlegada: double.parse(_kilometraje.text),
              combustibleLlegada: _combustible.text.trim(),
              observacionesLlegada: _observaciones.text.trim(),
            ),
          );
      ref.invalidate(rutasProvider);
      ref.invalidate(vehiculosProvider);
      ref.invalidate(mantenimientosProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _kilometraje.dispose();
    _combustible.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Finalizar ruta',
      formKey: _formKey,
      saving: _saving,
      onSubmit: _finish,
      submitLabel: 'Finalizar ruta',
      children: [
        Text('Ruta: ${widget.route.origen} - ${widget.route.destino}'),
        _field(_kilometraje, 'Kilometraje de llegada', number: true),
        _field(_combustible, 'Combustible de llegada'),
        _field(_observaciones, 'Observaciones', maxLines: 3),
      ],
    );
  }
}

class MantenimientoFormScreen extends ConsumerStatefulWidget {
  const MantenimientoFormScreen({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  ConsumerState<MantenimientoFormScreen> createState() =>
      _MantenimientoFormScreenState();
}

class _MantenimientoFormScreenState
    extends ConsumerState<MantenimientoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _cost = TextEditingController(text: '0');
  AveriaListModel? _averiaSeleccionada;
  bool _saving = false;

  Future<void> _seleccionarAveria() async {
    final averias = await ref
        .read(averiasVehiculoProvider(widget.vehicleId).future);
    if (!mounted) return;
    if (averias.isEmpty) {
      _showError(context, 'El vehiculo no tiene averias registradas.');
      return;
    }
    final seleccion = await showDialog<AveriaListModel>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Seleccione una averia'),
        children: [
          for (final a in averias)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, a),
              child:
                  Text('${a.categoria} - ${a.componente} (${a.criticidad})'),
            ),
        ],
      ),
    );
    if (seleccion != null && mounted) {
      setState(() => _averiaSeleccionada = seleccion);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_averiaSeleccionada == null) {
      _showError(context, 'Debe seleccionar una averia para el correctivo.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(transportesServiceProvider)
          .crearMantenimientoCorrectivo(
            CrearMantenimientoCorreactivoRequest(
              vehiculoId: widget.vehicleId,
              averiaId: _averiaSeleccionada!.id,
              descripcion: _description.text.trim(),
              costo: double.parse(_cost.text),
            ),
          );
      ref.invalidate(mantenimientosProvider);
      ref.invalidate(averiasProvider);
      ref.invalidate(vehiculosProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Nuevo mantenimiento',
      formKey: _formKey,
      saving: _saving,
      onSubmit: _save,
      children: [
        Text('Vehículo ${widget.vehicleId}'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: _seleccionarAveria,
            icon: const Icon(Icons.build),
            label: Text(
              _averiaSeleccionada == null
                  ? 'Seleccionar averia'
                  : '${_averiaSeleccionada!.categoria} - '
                      '${_averiaSeleccionada!.componente}',
            ),
          ),
        ),
        _field(_description, 'Descripción de la falla', maxLines: 3),
        _field(_cost, 'Costo', number: true),
      ],
    );
  }
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.formKey,
    required this.children,
    required this.saving,
    required this.onSubmit,
    this.submitLabel = 'Guardar',
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final bool saving;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...children,
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving ? null : onSubmit,
              child: saving
                  ? const CircularProgressIndicator()
                  : Text(submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool number = false,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType:
          number ? const TextInputType.numberWithOptions(decimal: true) : null,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Campo requerido';
        if (number && double.tryParse(value.trim()) == null) {
          return 'Ingrese un número válido';
        }
        return null;
      },
    ),
  );
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}
