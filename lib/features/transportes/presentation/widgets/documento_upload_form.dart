import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/documento_transporte.dart';
import '../../providers/jornadas_provider.dart';
import 'observacion_fields.dart';

Future<bool?> mostrarCargaDocumento(
        BuildContext context, String entidad, int id, {String? tipo}) =>
    showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => DocumentoUploadForm(
            entidad: entidad, titularId: id, tipoInicial: tipo));

class DocumentoUploadForm extends ConsumerStatefulWidget {
  const DocumentoUploadForm(
      {super.key,
      required this.entidad,
      required this.titularId,
      this.tipoInicial});
  final String entidad;
  final int titularId;
  final String? tipoInicial;
  @override
  ConsumerState<DocumentoUploadForm> createState() =>
      _DocumentoUploadFormState();
}

class _DocumentoUploadFormState extends ConsumerState<DocumentoUploadForm> {
  final _form = GlobalKey<FormState>();
  final _categoria = TextEditingController();
  String? _tipo, _nombre, _error;
  Uint8List? _bytes;
  DateTime? _fecha;
  bool _enviando = false, _adjuntando = false;
  Map<String, String> get tipos =>
      widget.entidad == 'conductor' ? documentosConductor : documentosVehiculo;
  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;
  }

  @override
  void dispose() {
    _categoria.dispose();
    super.dispose();
  }

  Future<void> _adjuntar(ImageSource? source) async {
    setState(() {
      _adjuntando = true;
      _error = null;
    });
    try {
      Uint8List? bytes;
      String? name;
      if (source == null) {
        final result = await FilePicker.platform.pickFiles(
            type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
        if (result != null) {
          bytes = result.files.single.bytes;
          name = result.files.single.name;
        }
        if (bytes != null &&
            (bytes.length < 5 ||
                String.fromCharCodes(bytes.take(5)) != '%PDF-')) {
          throw StateError('Seleccione un PDF válido.');
        }
      } else {
        final image = await ref.read(elegirFotoProvider)(source);
        if (image != null) {
          bytes = await image.readAsBytes();
          name = image.name;
        }
      }
      if (bytes == null) return;
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw StateError('Máximo 10 MB por archivo.');
      }
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _nombre = name;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _adjuntando = false);
    }
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    if (_bytes == null || (_tipo != 'tarjeta_propiedad' && _fecha == null)) {
      setState(() =>
          _error = 'Seleccione fecha de vencimiento y adjunte el archivo.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final enviada =
          await ref.read(transporteRepositoryProvider).subirDocumento(
              widget.entidad,
              widget.titularId,
              {
                'tipo': _tipo!,
                if (_fecha != null)
                  'fecha_vencimiento':
                      '${_fecha!.year}-${_fecha!.month.toString().padLeft(2, '0')}-${_fecha!.day.toString().padLeft(2, '0')}',
                if (_tipo == 'licencia')
                  'licencia_categoria': _categoria.text.trim(),
              },
              _bytes!,
              _nombre!);
      if (mounted) Navigator.pop(context, enviada);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .9,
          child: Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Row(children: [
                  const Expanded(
                      child: Text('Regularizar / Subir Documento',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold))),
                  IconButton(
                      onPressed:
                          _enviando ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close))
                ]),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de documento'),
                    items: tipos.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key,
                            child:
                                Text(e.value, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged:
                        _enviando ? null : (v) => setState(() => _tipo = v),
                    validator: (v) =>
                        v == null ? 'Seleccione el documento' : null),
                if (_tipo == 'licencia')
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextFormField(
                          controller: _categoria,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 20,
                          decoration: const InputDecoration(
                              labelText: 'Categoría de licencia',
                              hintText: 'Ej. A-IIb'),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Ingrese la categoría'
                              : null)),
                const SizedBox(height: 16),
                if (_tipo != 'tarjeta_propiedad')
                  OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(_fecha == null
                          ? 'Elegir fecha de vencimiento'
                          : 'Vence: ${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'),
                      onPressed: _enviando
                          ? null
                          : () async {
                              final now = DateTime.now();
                              final fecha = await showDatePicker(
                                  context: context,
                                  initialDate: _fecha ?? now,
                                  firstDate: DateTime(now.year - 10),
                                  lastDate: DateTime(now.year + 30));
                              if (fecha != null && mounted) {
                                setState(() => _fecha = fecha);
                              }
                            }),
                const SizedBox(height: 12),
                const Text(
                    'Foto comprimida automáticamente · PDF sin alterar · Hasta 10 MB'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                      onPressed: _enviando || _adjuntando
                          ? null
                          : () => _adjuntar(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Cámara')),
                  OutlinedButton.icon(
                      onPressed: _enviando || _adjuntando
                          ? null
                          : () => _adjuntar(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería')),
                  OutlinedButton.icon(
                      onPressed: _enviando || _adjuntando
                          ? null
                          : () => _adjuntar(null),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Archivo PDF')),
                ]),
                if (_adjuntando) const LinearProgressIndicator(),
                if (_bytes != null)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.attach_file),
                      title: Text(_nombre!, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${(_bytes!.length / 1024).toStringAsFixed(0)} KB'),
                      trailing: IconButton(
                          onPressed: _enviando
                              ? null
                              : () => setState(() {
                                    _bytes = null;
                                    _nombre = null;
                                  }),
                          icon: const Icon(Icons.close))),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 20),
                FilledButton.icon(
                    onPressed: _enviando || _adjuntando ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file),
                    label: Text(_enviando
                        ? 'Guardando documento…'
                        : 'Enviar documento')),
                const SizedBox(height: 30),
              ]))));
}
