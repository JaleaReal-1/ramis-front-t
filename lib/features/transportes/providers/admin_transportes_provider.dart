import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

final vehiculosListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarVehiculos();
});

final mantenimientosListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarMantenimientos();
});

final averiasListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarAverias();
});

final incidentesListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarIncidentes();
});

final rutasListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarRutas();
});
