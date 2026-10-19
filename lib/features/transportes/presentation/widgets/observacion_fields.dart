import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';
import 'package:sistema_ocs/core/config/api_config.dart';

typedef ElegirFoto = Future<XFile?> Function(ImageSource source);
final elegirFotoProvider = Provider<ElegirFoto>((ref) => (source) =>
    ImagePicker().pickImage(source: source, maxWidth: 1920, imageQuality: 85));

class ObservacionFields extends ConsumerStatefulWidget {
  const ObservacionFields(
      {super.key, required this.onChanged, this.obligatoria = false});
  final void Function(
          bool activa, String severidad, String descripcion, String? foto)
      onChanged;
  final bool obligatoria;
  @override
  ConsumerState<ObservacionFields> createState() => _ObservacionFieldsState();
}

class _ObservacionFieldsState extends ConsumerState<ObservacionFields> {
  bool _activa = false;
  bool _cargando = false;
  String _severidad = 'leve';
  String _descripcion = '';
  String? _foto;
  bool get activa => _activa || widget.obligatoria;
  void _notify() => widget.onChanged(activa, _severidad, _descripcion, _foto);
  Future<void> _pick(ImageSource source) async {
    try {
      final image = await ref.read(elegirFotoProvider)(source);
      if (image == null || !mounted) return;
      setState(() => _cargando = true);
      final bytes = await image.readAsBytes();
      final url = await ref
          .read(transporteRepositoryProvider)
          .subirFoto(bytes, image.name);
      if (!mounted) return;
      setState(() => _foto = url);
      _notify();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo adjuntar la foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
      type: MaterialType.transparency,
      child: Column(children: [
        SwitchListTile(
            title: const Text('¿Presenta Observaciones o Novedades?'),
            value: activa,
            onChanged: widget.obligatoria
                ? null
                : (v) {
                    setState(() => _activa = v);
                    _notify();
                  }),
        AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: activa
                ? Column(children: [
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _severidad,
                        decoration: const InputDecoration(
                            labelText: 'Severidad',
                            border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: 'leve',
                              child: Text('Leve · Alerta amarilla')),
                          DropdownMenuItem(
                              value: 'grave',
                              child: Text(
                                  'Grave / Crítica · Vehículo inoperativo',
                                  overflow: TextOverflow.ellipsis))
                        ],
                        onChanged: (v) {
                          setState(() => _severidad = v!);
                          _notify();
                        }),
                    const SizedBox(height: 12),
                    TextFormField(
                        initialValue: _descripcion,
                        decoration: const InputDecoration(
                            labelText: 'Descripción detallada',
                            border: OutlineInputBorder(),
                            helperText:
                                'Informar si hay alguna condición para revisar y/o reparar, reponer, implementar u oportunidades de mejora',
                            helperMaxLines: 4),
                        maxLines: 3,
                        onChanged: (v) {
                          _descripcion = v;
                          _notify();
                        },
                        validator: (v) =>
                            activa && (v == null || v.trim().isEmpty)
                                ? 'Describa la observación'
                                : null),
                    FormField<String>(
                        validator: (_) => activa && (_foto == null || _cargando)
                            ? 'Adjunte una fotografía y espere a que termine de cargar'
                            : null,
                        builder: (field) => Column(children: [
                              Wrap(children: [
                                TextButton.icon(
                                    onPressed: _cargando
                                        ? null
                                        : () => _pick(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Cámara')),
                                TextButton.icon(
                                    onPressed: _cargando
                                        ? null
                                        : () => _pick(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Galería')),
                                if (_foto != null)
                                  IconButton(
                                      onPressed: _cargando
                                          ? null
                                          : () {
                                              setState(() => _foto = null);
                                              _notify();
                                            },
                                      icon: const Icon(Icons.delete_outline)),
                              ]),
                              if (_cargando) const LinearProgressIndicator(),
                              if (_foto != null) FotoObservacion(url: _foto!),
                              if (field.hasError)
                                Text(field.errorText!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error)),
                            ])),
                  ])
                : const SizedBox.shrink()),
      ]));
}

Color colorSemaforo(String estado) => switch (estado) {
      'rojo' => Colors.red,
      'amarillo' => Colors.orange,
      _ => Colors.green
    };

class FotoObservacion extends StatelessWidget {
  const FotoObservacion({super.key, required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    final ruta = '${ApiConfig.baseUrl}$url';
    return InkWell(
        onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context))),
                  Flexible(
                      child: InteractiveViewer(
                          child: Image.network(ruta,
                              errorBuilder: (_, __, ___) =>
                                  const Text('Foto no disponible')))),
                ]))),
        child: Image.network(ruta,
            height: 120,
            errorBuilder: (_, __, ___) => const Text('Foto no disponible')));
  }
}
