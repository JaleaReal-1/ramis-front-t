import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/documento_transporte.dart';
import '../../providers/documentos_provider.dart';
import '../../providers/jornadas_provider.dart';
import '../../data/save_download.dart';
import '../widgets/documento_upload_form.dart';

Color colorDocumento(String estado) => switch (estado) {
      'verde' => Colors.green,
      'amarillo' => Colors.orange,
      'rojo' || 'vencido' => Colors.red,
      _ => Colors.grey,
    };

class MisDocumentosScreen extends ConsumerWidget {
  const MisDocumentosScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(currentUserForTransportProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text('No se pudo identificar al conductor: $e')),
          data: (user) => user == null
              ? const Center(
                  child: Text('Inicie sesión para ver sus documentos.'))
              : DocumentosScreen(
                  entidad: 'conductor',
                  titularId: user.id,
                  titulo: 'Mis Documentos',
                  embedded: embedded));
}

class DocumentosScreen extends ConsumerStatefulWidget {
  const DocumentosScreen(
      {super.key,
      required this.entidad,
      required this.titularId,
      this.titulo = 'Documentación',
      this.administrar = false,
      this.embedded = false});
  final String entidad, titulo;
  final int titularId;
  final bool administrar, embedded;
  @override
  ConsumerState<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends ConsumerState<DocumentosScreen> {
  bool _ocupado = false;
  String? _mensaje;
  int _pendientes = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _actualizarPendientes();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await _actualizarPendientes();
        await _refresh();
      } catch (_) {/* La consola mantiene los datos locales. */}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _actualizarPendientes() async {
    try {
      final count = await ref
          .read(transporteRepositoryProvider)
          .queue
          .pendingDocuments(widget.entidad, widget.titularId);
      if (mounted) setState(() => _pendientes = count);
    } catch (_) {/* Sin sesión no se consultan documentos de otras cuentas. */}
  }

  TitularDocumento get titular =>
      (entidad: widget.entidad, id: widget.titularId);
  Future<void> _refresh() async {
    ref.invalidate(documentosProvider(titular));
    ref.invalidate(conductoresV3Provider);
    await ref.read(documentosProvider(titular).future);
  }

  Future<void> _subir([String? tipo]) async {
    final enviada = await mostrarCargaDocumento(
        context, widget.entidad, widget.titularId,
        tipo: tipo);
    if (enviada == null || !mounted) return;
    setState(() => _mensaje = enviada
        ? 'Documento enviado correctamente.'
        : 'Documento guardado sin conexión. Se enviará automáticamente al recuperar señal.');
    await _actualizarPendientes();
    if (enviada) await _refresh();
  }

  Future<void> _ver(String path) async {
    setState(() => _ocupado = true);
    try {
      final bytes =
          await ref.read(transporteRepositoryProvider).descargarArchivo(path);
      if (!mounted) return;
      final name = Uri.parse(path).pathSegments.last;
      if (!name.toLowerCase().endsWith('.pdf')) {
        await Navigator.push<void>(
            context,
            MaterialPageRoute(
                builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Documento adjunto')),
                    body: Center(
                        child: InteractiveViewer(
                            child: Image.memory(Uint8List.fromList(bytes)))))));
      } else if (kIsWeb) {
        await FilePicker.platform
            .saveFile(fileName: name, bytes: Uint8List.fromList(bytes));
      } else {
        await openDownloadedFile(name, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir el archivo: $e')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _revisar(DocumentoTransporte documento, bool aprobar) async {
    final motivo = TextEditingController();
    final form = GlobalKey<FormState>();
    final aceptado = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                scrollable: true,
                title:
                    Text(aprobar ? 'Aprobar documento' : 'Rechazar documento'),
                content: aprobar
                    ? const Text(
                        'Confirme que revisó el archivo, la categoría y el vencimiento.')
                    : Form(
                        key: form,
                        child: TextFormField(
                            controller: motivo,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Motivo del rechazo',
                                helperText: 'Mínimo 10 caracteres'),
                            validator: (v) => (v ?? '').trim().length < 10
                                ? 'Explique el motivo (mínimo 10 caracteres)'
                                : null)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Volver')),
                  FilledButton(
                      onPressed: () {
                        if (aprobar || form.currentState!.validate()) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      child: Text(aprobar ? 'Aprobar' : 'Confirmar rechazo'))
                ]));
    final razon = motivo.text.trim();
    motivo.dispose();
    if (aceptado != true || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await ref.read(transporteRepositoryProvider).revisarDocumento(
          documento.id!, aprobar ? 'aprobado' : 'rechazado', razon);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentos = ref.watch(documentosProvider(titular));
    final catalogo = widget.entidad == 'conductor'
        ? documentosConductor
        : documentosVehiculo;
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(widget.titulo), actions: [
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))
            ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _ocupado ? null : _subir,
          icon: const Icon(Icons.upload_file),
          label: const Text('Regularizar / Subir Documento')),
      body: documentos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('No se pudieron cargar los documentos: $e'),
                    TextButton(
                        onPressed: _refresh, child: const Text('Reintentar')),
                    OutlinedButton(
                        onPressed: () => _subir(),
                        child: const Text('Subir documento sin conexión'))
                  ]))),
          data: (items) => RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  children: [
                    if (_pendientes > 0)
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                  '$_pendientes documento(s) guardado(s) · Pendiente de sincronización'))),
                    if (_mensaje != null)
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_mensaje!))),
                    if (_ocupado) const LinearProgressIndicator(),
                    for (final entry in catalogo.entries)
                      _card(
                          entry.key,
                          entry.value,
                          items.where((d) => d.tipo == entry.key).firstOrNull ??
                              DocumentoTransporte.fromJson(
                                  {'tipo': entry.key})),
                    ExpansionTile(
                        title: const Text('Historial de versiones'),
                        children: [
                          TextButton(
                              onPressed: () async {
                                try {
                                  final rows = await ref
                                      .read(transporteRepositoryProvider)
                                      .historialDocumentos(
                                          widget.entidad, widget.titularId);
                                  if (!context.mounted) return;
                                  await Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => Scaffold(
                                              appBar: AppBar(
                                                  title: const Text(
                                                      'Historial documental')),
                                              body: ListView(children: [
                                                for (final row in rows)
                                                  ListTile(
                                                      title: Text(
                                                          '${catalogo[row['tipo']] ?? row['tipo']} · Versión ${row['version']}'),
                                                      subtitle: Text(
                                                          '${row['estado']} · ${row['archivado'] == true ? 'Archivado' : 'Actual'}'),
                                                      trailing:
                                                          row['archivo_url'] ==
                                                                  null
                                                              ? null
                                                              : const Icon(Icons
                                                                  .open_in_new),
                                                      onTap: row['archivo_url'] ==
                                                              null
                                                          ? null
                                                          : () => _ver(
                                                              row['archivo_url']
                                                                  as String))
                                              ]))));
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('$e')));
                                  }
                                }
                              },
                              child: const Text('Consultar historial')),
                        ]),
                  ]))),
    );
  }

  Widget _card(String tipo, String titulo, DocumentoTransporte d) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              Chip(
                  avatar: Icon(Icons.circle,
                      size: 16, color: colorDocumento(d.semaforo)),
                  label: Text(d.semaforo.toUpperCase())),
              Chip(label: Text('Estado: ${d.estado}'))
            ]),
            if (tipo == 'licencia')
              Text('Categoría: ${d.categoria ?? 'Pendiente'}'),
            Text('Vencimiento: ${d.vencimiento}'),
            if (d.dias != null)
              Text(d.dias! < 0
                  ? 'Vencido hace ${-d.dias!} días'
                  : 'Días restantes: ${d.dias}'),
            if (d.motivo != null)
              Text('Motivo: ${d.motivo}',
                  style: const TextStyle(color: Colors.red)),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (d.archivo != null)
                TextButton.icon(
                    onPressed: _ocupado ? null : () => _ver(d.archivo!),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver archivo')),
              OutlinedButton(
                  onPressed: _ocupado ? null : () => _subir(tipo),
                  child: Text(d.archivo == null
                      ? 'Subir documento'
                      : 'Actualizar documento')),
              if (widget.administrar &&
                  d.id != null &&
                  d.estado == 'pendiente') ...[
                FilledButton(
                    onPressed: _ocupado ? null : () => _revisar(d, true),
                    child: const Text('Aprobar')),
                TextButton(
                    onPressed: _ocupado ? null : () => _revisar(d, false),
                    child: const Text('Rechazar')),
              ],
            ]),
          ])));
}
