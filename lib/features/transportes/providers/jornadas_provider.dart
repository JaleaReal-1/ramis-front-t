import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/data/network/dio_client.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';

// ── Repository ──────────────────────────────────────────────

final transporteRepositoryProvider = Provider<TransporteRepositoryImpl>((ref) {
  final repo = TransporteRepositoryImpl(ref.watch(dioProvider));
  repo.queue.start();
  ref.onDispose(repo.queue.dispose);
  return repo;
});

// ── Current User ────────────────────────────────────────────

final currentUserForTransportProvider = FutureProvider((ref) async {
  if (ref.watch(authNotifierProvider) != AuthStatus.authenticated) return null;
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});

// ── Vehículos (solo admin) ──────────────────────────────────

final vehiculosDisponiblesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final userAsync = await ref.watch(currentUserForTransportProvider.future);
  if (userAsync == null) return [];
  if (userAsync.role != 'admin' && userAsync.role != 'conductor') return [];
  final repo = ref.watch(transporteRepositoryProvider);
  return repo.listarVehiculos();
});

// ── Trabajadores (solo admin) ───────────────────────────────

final trabajadoresProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final userAsync = await ref.watch(currentUserForTransportProvider.future);
  if (userAsync == null || userAsync.role != 'admin') return [];
  final repo = ref.watch(transporteRepositoryProvider);
  final allTrabajadores = await repo.listarTrabajadores();
  // Filtrar estrictamente solo a los conductores
  return allTrabajadores.where((t) => t['role'] == 'conductor').toList();
});

// ── Mi Jornada (trabajador) ─────────────────────────────────

final vehiculoJornadaProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
  final timer =
      Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(transporteRepositoryProvider).obtenerVehiculo(id);
});

final miJornadaProvider = FutureProvider<JornadaTransporte?>((ref) async {
  final timer =
      Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final user = await ref.watch(currentUserForTransportProvider.future);
  if (user == null) return null;
  final repo = ref.watch(transporteRepositoryProvider);
  final jornadas = await repo.listarJornadas();
  final activas = jornadas.where((j) =>
      j.conductorId == user.id &&
      j.jornadaPadreId == null &&
      (['pendiente', 'en_curso', 'pendiente_de_cierre', 'cerrada_por_sistema']
          .contains(j.estado)) &&
      j.vehiculoId != null);
  if (activas.isEmpty) return null;
  return repo.obtenerJornada(activas.first.id);
});

// ── Jornada Notifier (state management) ─────────────────────

class JornadaNotifier extends StateNotifier<AsyncValue<JornadaTransporte?>> {
  JornadaNotifier(this._repository)
      : super(const AsyncValue<JornadaTransporte?>.data(null));

  final TransporteRepositoryImpl _repository;

  Future<void> asignar(AsignarJornadaRequest request) async {
    await _execute(() => _repository.asignar(request));
  }

  Future<void> registrarAccion(RegistroAccionRequest request) async {
    if (request.accionTipo != 'Empezar a Conducir') {
      await _repository.registrarAccion(request);
      final actual = state.value;
      if (actual != null) await refreshJornada(actual.id);
      return;
    }
    await _execute(() async {
      final jornada = await _repository.registrarAccion(request);
      if (jornada.vehiculoId != request.vehiculoId) {
        throw const TransportFailure(
          message: 'El servidor no devolvió el vehículo de la jornada.',
        );
      }
      return jornada;
    });
  }

  Future<void> registrarChecklistInicial(
    int jornadaId,
    ChecklistRequest request,
  ) async {
    await _execute(
      () => _repository.registrarChecklistInicial(jornadaId, request),
    );
  }

  Future<void> registrarIncidencia(
    int jornadaId,
    IncidenciaRutaRequest request,
  ) async {
    final previous = state.value;
    state = const AsyncValue.loading();
    try {
      await _repository.registrarIncidencia(jornadaId, request);
      state = AsyncValue.data(await _repository.obtenerJornada(jornadaId));
    } catch (error) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> registrarChecklistFinal(
    int jornadaId,
    ChecklistRequest request,
  ) async {
    await _execute(
      () => _repository.registrarChecklistFinal(jornadaId, request),
    );
  }

  Future<void> refreshJornada(int jornadaId) async {
    await _execute(() => _repository.obtenerJornada(jornadaId));
  }

  /// Executes an operation that returns a JornadaTransporte.
  /// On success: updates state with the result.
  /// On failure: retains previous data to avoid blanking the screen, then rethrows.
  Future<void> _execute(
    Future<JornadaTransporte> Function() operation,
  ) async {
    final previous = state.value;
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await operation());
    } catch (error, _) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }
}

final jornadaNotifierProvider =
    StateNotifierProvider<JornadaNotifier, AsyncValue<JornadaTransporte?>>(
  (ref) => JornadaNotifier(ref.watch(transporteRepositoryProvider)),
);

/// Acciones registradas por el conductor, incluidas las que siguen en curso.
final accionesRegistradasProvider =
    FutureProvider.autoDispose<List<JornadaTransporte>>((ref) async {
  final user = await ref.watch(currentUserForTransportProvider.future);
  if (user == null) return [];
  final repo = ref.watch(transporteRepositoryProvider);
  final jornadas = await repo.listarJornadas();
  return jornadas
      .where((j) => j.conductorId == user.id && j.accionTipo != null)
      .toList()
    ..sort((a, b) => b.id.compareTo(a.id));
});

final detalleAccionProvider =
    FutureProvider.autoDispose.family<JornadaTransporte, int>((ref, id) async {
  return ref.watch(transporteRepositoryProvider).obtenerJornada(id);
});
