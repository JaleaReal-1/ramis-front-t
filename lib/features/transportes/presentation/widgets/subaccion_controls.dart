import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/jornada_transporte.dart';
import '../../providers/jornadas_provider.dart';
import 'odometro_confirm.dart';

class SubaccionControls extends ConsumerWidget {
  const SubaccionControls(
      {super.key, required this.subaccion, required this.onChanged});
  final JornadaTransporte subaccion;
  final Future<void> Function() onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
      color: subaccion.estado == 'cancelada' ? Colors.grey.shade200 : null,
      child: ListTile(
          title: Text('${subaccion.accionTipo} · ${subaccion.estado}'),
          subtitle: subaccion.estado == 'cancelada'
              ? Text(
                  '${subaccion.motivoCancelacion ?? ""} · Responsable: ${subaccion.canceladoPorId ?? "Sistema"}')
              : null,
          trailing: subaccion.estado == 'en_curso'
              ? Wrap(children: [
                  TextButton(
                      onPressed: () => _cerrar(context, ref),
                      child: const Text('Cerrar')),
                  TextButton(
                      onPressed: () => _cancelar(context, ref),
                      child: const Text('Cancelar')),
                ])
              : null));

  Future<void> _cerrar(BuildContext context, WidgetRef ref) async {
    final grua = subaccion.accionTipo == 'Operar Grúa';
    final valor = TextEditingController();
    final texto = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(grua ? 'Horómetro final' : 'Odómetro actual'),
                content: TextField(
                    controller: valor,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Volver')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, valor.text),
                      child: const Text('Cerrar actividad'))
                ]));
    valor.dispose();
    final numero = double.tryParse((texto ?? '').replaceAll(',', '.'));
    if (numero == null || !numero.isFinite || !context.mounted) return;
    try {
      final evidencia = grua
          ? <String, String>{}
          : await confirmarOdometro(
              context, numero - (subaccion.kmInicial ?? numero));
      if (evidencia == null) return;
      await ref.read(transporteRepositoryProvider).cerrarSubaccion(subaccion.id,
          {grua ? 'horometro_final' : 'km_final': numero, ...evidencia});
      await onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    final aceptar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Cancelar actividad'),
                content: const Text(
                    'La actividad conservará su historial y quedará marcada como cancelada.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Volver')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Continuar'))
                ]));
    if (aceptar != true || !context.mounted) return;
    final motivo = TextEditingController();
    final razon = await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: const Text('Motivo obligatorio'),
                    content: TextField(
                        controller: motivo,
                        onChanged: (_) => update(() {}),
                        decoration: const InputDecoration(
                            helperText: 'Mínimo 10 caracteres')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Volver')),
                      FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: motivo.text.trim().length < 10
                              ? null
                              : () => Navigator.pop(ctx, motivo.text.trim()),
                          child: const Text('Confirmar cancelación'))
                    ])));
    motivo.dispose();
    if (razon == null) return;
    try {
      await ref
          .read(transporteRepositoryProvider)
          .cancelarSubaccion(subaccion.id, razon);
      await onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
