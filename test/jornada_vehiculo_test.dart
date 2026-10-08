import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/data/models/user_model.dart';
import 'package:sistema_ocs/features/transportes/data/models/jornada_transporte_model.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

class _FakeRepository extends TransporteRepositoryImpl {
  _FakeRepository(this.created) : super(Dio());

  final JornadaTransporte created;
  final active = const JornadaTransporte(
    id: 2,
    conductorId: 7,
    estado: 'en_curso',
    vehiculoId: 42,
  );

  @override
  Future<List<JornadaTransporte>> listarJornadas() async => [
        const JornadaTransporte(
          id: 3,
          conductorId: 7,
          estado: 'en_curso',
        ),
        active,
      ];

  @override
  Future<JornadaTransporte> obtenerJornada(int jornadaId) async => active;

  @override
  Future<JornadaTransporte> registrarAccion(
          RegistroAccionRequest request) async =>
      created;
}

void main() {
  test('El JSON snake_case conserva el ID del vehículo', () {
    final jornada = JornadaTransporteModel.fromJson({
      'id': 2,
      'conductor_id': 7,
      'estado': 'en_curso',
      'vehiculo_id': 42,
    });
    expect(jornada.vehiculoId, 42);
  });

  test('La jornada activa omite registros sin vehículo', () async {
    final repository = _FakeRepository(const JornadaTransporte(
      id: 4,
      conductorId: 7,
      estado: 'en_curso',
      vehiculoId: 42,
    ));
    final container = ProviderContainer(overrides: [
      transporteRepositoryProvider.overrideWithValue(repository),
      currentUserForTransportProvider.overrideWith((ref) async => UserModel(
            id: 7,
            nombre: 'Conductor',
            apellidos: 'Prueba',
            email: 'conductor@test.com',
            role: 'conductor',
          )),
    ]);
    addTearDown(container.dispose);

    expect((await container.read(miJornadaProvider.future))?.vehiculoId, 42);
    await container.read(jornadaNotifierProvider.notifier).registrarAccion(
          const RegistroAccionRequest(
            accionTipo: 'Empezar a Conducir',
            vehiculoId: 42,
            nivelCombustible: 50,
            observaciones: 'Sin novedad',
          ),
        );
    expect(container.read(jornadaNotifierProvider).value?.vehiculoId, 42);
  });

  test('El estado rechaza una respuesta de conducción sin vehículo', () async {
    final repository = _FakeRepository(const JornadaTransporte(
      id: 4,
      conductorId: 7,
      estado: 'en_curso',
    ));
    final container = ProviderContainer(overrides: [
      transporteRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);

    await expectLater(
      container.read(jornadaNotifierProvider.notifier).registrarAccion(
            const RegistroAccionRequest(
              accionTipo: 'Empezar a Conducir',
              vehiculoId: 42,
              nivelCombustible: 50,
              observaciones: 'Sin novedad',
            ),
          ),
      throwsA(isA<TransportFailure>()),
    );
    expect(container.read(jornadaNotifierProvider).value, isNull);
  });
}
