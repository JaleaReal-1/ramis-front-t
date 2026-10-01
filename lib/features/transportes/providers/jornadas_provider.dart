import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/data/network/dio_client.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';

// ── Repository ──────────────────────────────────────────────

final transporteRepositoryProvider = Provider<TransporteRepositoryImpl>((ref) {
  return TransporteRepositoryImpl(ref.watch(dioProvider));
});

// ── Current User ────────────────────────────────────────────

final currentUserForTransportProvider = FutureProvider((ref) async {
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

final miJornadaProvider = FutureProvider<JornadaTransporte?>((ref) async {
  try {
    final user = await ref.watch(currentUserForTransportProvider.future);
    if (user == null) return null;
    final repo = ref.watch(transporteRepositoryProvider);
    final jornadas = await repo.listarJornadas();
    final activas = jornadas.where(
      (j) =>
          j.conductorId == user.id &&
          (j.estado == 'pendiente' || j.estado == 'en_curso'),
    );
    if (activas.isEmpty) return null;
    // Fetch detail for the first active jornada to get checklists/incidencias
    return repo.obtenerJornada(activas.first.id);
  } on TransportFailure {
    return null;
  }
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
    await _execute(() => _repository.registrarAccion(request));
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
      // Retain previous jornada state (incidencia doesn't change jornada estado)
      state = AsyncValue.data(previous);
    } catch (error, stack) {
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
