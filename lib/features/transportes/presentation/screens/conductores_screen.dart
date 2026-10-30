import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/documento_transporte.dart';
import '../../providers/documentos_provider.dart';
import '../../providers/jornadas_provider.dart';
import 'documentos_screen.dart';

class ConductoresScreen extends ConsumerStatefulWidget {
  const ConductoresScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  ConsumerState<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends ConsumerState<ConductoresScreen> {
  String _buscar = '';
  Future<void> _refresh() async {
    ref.invalidate(conductoresV3Provider);
    await ref.read(conductoresV3Provider.future);
  }

  Future<void> _formulario([Map<String, dynamic>? conductor]) async {
    final cambiado = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ConductorForm(conductor: conductor));
    if (cambiado == true) await _refresh();
  }

  void _documentos(Map<String, dynamic> c) => Navigator.push<void>(
      context,
      MaterialPageRoute(
          builder: (_) => DocumentosScreen(
              entidad: 'conductor',
              titularId: (c['id'] as num).toInt(),
              administrar: true,
              titulo: 'Documentos · ${c['nombre']} ${c['apellidos']}')));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Conductores')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _formulario,
          icon: const Icon(Icons.person_add),
          label: const Text('Alta Rápida de Conductor')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
                onChanged: (v) => setState(() => _buscar = v.toLowerCase()),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar por DNI o nombre'))),
        Expanded(
            child: ref.watch(conductoresV3Provider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('No se pudieron cargar los conductores: $e'),
                          TextButton(
                              onPressed: _refresh,
                              child: const Text('Reintentar'))
                        ]))),
                data: (lista) {
                  final rows = lista
                      .where((c) =>
                          '${c['dni']} ${c['nombre']} ${c['apellidos']}'
                              .toLowerCase()
                              .contains(_buscar))
                      .toList();
                  return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
                          children: [
                            if (rows.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.all(24),
                                  child:
                                      Text('No hay conductores para mostrar.')),
                            for (final c in rows)
                              Card(
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${c['nombre']} ${c['apellidos']}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18)),
                                            Text('DNI: ${c['dni']}'),
                                            Text('Correo: ${c['email']}'),
                                            const SizedBox(height: 8),
                                            Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  for (final tipo
                                                      in documentosConductor
                                                          .keys)
                                                    Builder(builder: (_) {
                                                      final docs =
                                                          (c['documentos']
                                                                      as List? ??
                                                                  [])
                                                              .whereType<Map>()
                                                              .where((d) =>
                                                                  d['tipo'] ==
                                                                  tipo);
                                                      final doc = docs.isEmpty
                                                          ? <String, dynamic>{}
                                                          : docs.first;
                                                      final color = (doc[
                                                                  'semaforo'] ??
                                                              doc['estado'] ??
                                                              'pendiente')
                                                          as String;
                                                      return Chip(
                                                          avatar: Icon(
                                                              Icons.circle,
                                                              size: 14,
                                                              color:
                                                                  colorDocumento(
                                                                      color)),
                                                          label: Text(
                                                              '${tipo == 'licencia' ? 'Licencia' : tipo == 'emo' ? 'EMO' : 'Pase Minero'}: $color'));
                                                    })
                                                ]),
                                            Wrap(spacing: 8, children: [
                                              FilledButton.tonalIcon(
                                                  onPressed: () =>
                                                      _documentos(c),
                                                  icon: const Icon(
                                                      Icons.fact_check),
                                                  label: const Text(
                                                      'Revisar Documentos')),
                                              OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _formulario(c),
                                                  icon: const Icon(
                                                      Icons.manage_accounts),
                                                  label: const Text(
                                                      'Configurar Acceso')),
                                            ]),
                                          ]))),
                          ]));
                })),
      ]));
}

class ConductorForm extends ConsumerStatefulWidget {
  const ConductorForm({super.key, this.conductor});
  final Map<String, dynamic>? conductor;
  @override
  ConsumerState<ConductorForm> createState() => _ConductorFormState();
}

class _ConductorFormState extends ConsumerState<ConductorForm> {
  final _form = GlobalKey<FormState>();
  final _dni = TextEditingController(),
      _nombre = TextEditingController(),
      _apellidos = TextEditingController();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _guardando = false, _visible = false;
  String? _error;
  bool get acceso => widget.conductor != null;
  @override
  void initState() {
    super.initState();
    _email.text = widget.conductor?['email'] as String? ?? '';
  }

  @override
  void dispose() {
    for (final c in [_dni, _nombre, _apellidos, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final repo = ref.read(transporteRepositoryProvider);
      if (acceso) {
        await repo.configurarAcceso((widget.conductor!['id'] as num).toInt(),
            _email.text.trim(), _password.text);
      } else {
        await repo.altaConductor(
            _dni.text.trim(), _nombre.text.trim(), _apellidos.text.trim());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
          child: Form(
              key: _form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        acceso
                            ? 'Configurar Acceso'
                            : 'Alta Rápida de Conductor',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    if (!acceso) ...[
                      TextFormField(
                          controller: _dni,
                          maxLength: 8,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'DNI'),
                          validator: (v) => RegExp(r'^\d{8}$').hasMatch(v ?? '')
                              ? null
                              : 'Ingrese 8 dígitos'),
                      TextFormField(
                          controller: _nombre,
                          decoration:
                              const InputDecoration(labelText: 'Nombres'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v ?? '').trim().length < 2
                              ? 'Ingrese los nombres'
                              : null),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _apellidos,
                          decoration:
                              const InputDecoration(labelText: 'Apellidos'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v ?? '').trim().length < 2
                              ? 'Ingrese los apellidos'
                              : null),
                    ] else ...[
                      Text(
                          '${widget.conductor!['nombre']} ${widget.conductor!['apellidos']}'),
                      TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Correo electrónico'),
                          validator: (v) =>
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch((v ?? '').trim())
                                  ? null
                                  : 'Ingrese un correo válido'),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _password,
                          obscureText: !_visible,
                          maxLength: 128,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                              labelText: 'Contraseña inicial',
                              suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _visible = !_visible),
                                  icon: Icon(_visible
                                      ? Icons.visibility_off
                                      : Icons.visibility))),
                          validator: (v) => (v ?? '').length < 8
                              ? 'Mínimo 8 caracteres'
                              : null),
                    ],
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    const SizedBox(height: 24),
                    FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        child: Text(_guardando ? 'Guardando…' : 'Guardar')),
                  ]))));
}
