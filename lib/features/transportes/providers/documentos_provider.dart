import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/documento_transporte.dart';
import 'jornadas_provider.dart';

typedef TitularDocumento = ({String entidad, int id});
final documentosProvider = FutureProvider.autoDispose
    .family<List<DocumentoTransporte>, TitularDocumento>((ref, titular) async {
  final rows = await ref
      .watch(transporteRepositoryProvider)
      .documentos(titular.entidad, titular.id);
  return rows.map(DocumentoTransporte.fromJson).toList();
});
final conductoresV3Provider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => ref.watch(transporteRepositoryProvider).listarConductores());
