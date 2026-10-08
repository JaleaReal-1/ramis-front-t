import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/data/models/user_model.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/conductor_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

class _AccionesRepository extends TransporteRepositoryImpl {
  _AccionesRepository() : super(Dio());

  @override
  Future<List<JornadaTransporte>> listarJornadas() async => [
        JornadaTransporte(
          id: 2,
          conductorId: 9,
          vehiculoId: 3,
          estado: 'finalizada',
          accionTipo: 'Operar Grúa',
        ),
        JornadaTransporte(
          id: 1,
          conductorId: 7,
          vehiculoId: 5,
          estado: 'finalizada',
          accionTipo: 'Operar Grúa',
          fechaInicio: DateTime(2026, 10, 8),
        ),
      ];

  @override
  Future<JornadaTransporte> obtenerJornada(int jornadaId) async =>
      JornadaTransporte(
        id: jornadaId,
        conductorId: 7,
        vehiculoId: 5,
        estado: 'finalizada',
        accionTipo: 'Operar Grúa',
        kmInicial: 125,
        nivelCombustible: 50,
        observaciones: 'Sin novedad',
        detallesGrua: const {
          'actividad': 'Izaje de carga',
          'horometro_inicial': 10.5,
          'horometro_final': 11.5,
        },
      );

  @override
  Future<List<Map<String, dynamic>>> listarVehiculos() async => [];
}

void main() {
  testWidgets('Separa acciones del trabajador y formulario nuevo en móvil',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        transporteRepositoryProvider.overrideWithValue(_AccionesRepository()),
        currentUserForTransportProvider.overrideWith((ref) async => UserModel(
              id: 7,
              nombre: 'Ana',
              apellidos: 'Ramis',
              email: 'ana@test.com',
              role: 'conductor',
            )),
      ],
      child: const MaterialApp(home: ConductorJornadaScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Lo que registraste'), findsOneWidget);
    expect(find.text('Operar Grúa'), findsOneWidget);
    expect(find.text('08/10/2026 · Finalizada'), findsOneWidget);
    await tester.tap(find.text('Operar Grúa'));
    await tester.pumpAndSettle();
    expect(find.text('Izaje de carga'), findsOneWidget);
    expect(find.text('125.0 km'), findsOneWidget);
    expect(find.text('Sin novedad'), findsOneWidget);

    await tester.tap(find.text('Nueva acción'));
    await tester.pumpAndSettle();
    expect(find.text('Registro de Actividad'), findsOneWidget);
    expect(find.text('ACCIÓN A REALIZAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
