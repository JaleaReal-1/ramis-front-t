import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/data/network/dio_client.dart';
import 'package:sistema_ocs/features/transportes/models/averia_model.dart';
import 'package:sistema_ocs/features/transportes/models/incidente_model.dart';
import 'package:sistema_ocs/features/transportes/models/inspeccion_model.dart';
import 'package:sistema_ocs/features/transportes/models/mantenimiento_model.dart';
import 'package:sistema_ocs/features/transportes/models/ruta_asignacion_model.dart';
import 'package:sistema_ocs/features/transportes/models/vehiculo_model.dart';
import 'package:sistema_ocs/features/transportes/services/transportes_service.dart';

final transportesServiceProvider = Provider<TransportesService>((ref) {
  return TransportesService(ref.watch(dioProvider));
});

final vehiculosProvider = FutureProvider<List<VehiculoModel>>((ref) {
  return ref.watch(transportesServiceProvider).listarVehiculos();
});

final rutasProvider = FutureProvider<List<RutaAsignacionModel>>((ref) {
  return ref.watch(transportesServiceProvider).listarRutas();
});

final mantenimientosProvider =
    FutureProvider<List<MantenimientoListModel>>((ref) {
  return ref.watch(transportesServiceProvider).listarMantenimientos();
});

final checklistItemsProvider =
    FutureProvider<List<ChecklistItemModel>>((ref) {
  return ref.watch(transportesServiceProvider).listarChecklistItems();
});

final inspeccionesProvider = FutureProvider<List<InspeccionListModel>>((ref) {
  return ref.watch(transportesServiceProvider).listarInspecciones();
});

final averiasProvider = FutureProvider<List<AveriaListModel>>((ref) {
  return ref.watch(transportesServiceProvider).listarAverias();
});

final incidentesProvider = FutureProvider<List<IncidenteListModel>>((ref) {
  return ref.watch(transportesServiceProvider).listarIncidentes();
});

final vehiculoProvider = FutureProvider.family<VehiculoModel, int>((ref, id) {
  return ref.watch(transportesServiceProvider).obtenerVehiculo(id);
});

final rutaProvider = FutureProvider.family<RutaAsignacionModel, int>((ref, id) {
  return ref.watch(transportesServiceProvider).obtenerRuta(id);
});

final mantenimientoProvider =
    FutureProvider.family<MantenimientoModel, int>((ref, id) {
  return ref.watch(transportesServiceProvider).obtenerMantenimiento(id);
});

/// Historial de mantenimientos por vehículo
final mantenimientosVehiculoProvider =
    FutureProvider.family<List<MantenimientoListModel>, int>((ref, vehiculoId) {
  return ref.watch(transportesServiceProvider).mantenimientosVehiculo(
        vehiculoId,
      );
});

/// Historial de inspecciones por vehículo
final inspeccionesVehiculoProvider =
    FutureProvider.family<List<InspeccionListModel>, int>((ref, vehiculoId) {
  return ref
      .watch(transportesServiceProvider)
      .historialInspeccionesVehiculo(vehiculoId);
});

/// Historial de averías por vehículo
final averiasVehiculoProvider =
    FutureProvider.family<List<AveriaListModel>, int>((ref, vehiculoId) {
  return ref.watch(transportesServiceProvider).historialAveriasVehiculo(
        vehiculoId,
      );
});

/// Historial de incidentes por vehículo
final incidentesVehiculoProvider =
    FutureProvider.family<List<IncidenteListModel>, int>((ref, vehiculoId) {
  return ref.watch(transportesServiceProvider).historialIncidentesVehiculo(
        vehiculoId,
      );
});
