import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

final vehiculosListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final timer =
      Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarVehiculos();
});

final mantenimientosListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final timer =
      Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarMantenimientos();
});

final averiasListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final timer =
      Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarAverias();
});

final incidentesListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final timer =
      Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarIncidentes();
});

final rutasListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final timer =
      Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarRutas();
});

/// Lista completa de jornadas (para el admin)
final jornadasListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final timer =
      Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarJornadas().then((list) => list
      .map((j) => {
            'id': j.id,
            'conductor_id': j.conductorId,
            'vehiculo_id': j.vehiculoId,
            'estado': j.estado,
            'estado_semaforo': j.estadoSemaforo,
            'foto_observacion': j.fotoObservacion,
            'jornada_padre_id': j.jornadaPadreId,
            'galones_consumidos': j.galonesConsumidos,
            'rendimiento_km_galon': j.rendimientoKmGalon,
            'km_inicial': j.kmInicial,
            'km_final': j.kmFinal,
            'accion_tipo': j.accionTipo,
            'observaciones': j.observaciones,
            'alerta_horas': j.alertaHoras,
            'alerta_km': j.alertaKm,
            'fecha_inicio': j.fechaInicio?.toIso8601String(),
            'fecha_fin': j.fechaFin?.toIso8601String(),
          })
      .toList());
});
