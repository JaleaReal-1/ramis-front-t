import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/data/models/user_model.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/fuel_gauge_selector.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/registro_accion_form.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

class _FakeRepository extends TransporteRepositoryImpl {
  _FakeRepository() : super(Dio());

  RegistroAccionRequest? submitted;

  @override
  Future<double> obtenerKilometrajeVehiculo(int vehiculoId) async => 125.0;

  @override
  Future<JornadaTransporte> registrarAccion(
      RegistroAccionRequest request) async {
    submitted = request;
    return JornadaTransporte(
      id: 1,
      conductorId: 7,
      vehiculoId: request.vehiculoId,
      estado: 'en_curso',
    );
  }
}

void main() {
  testWidgets('Incidencias va directo a observaciones y F conserva placeholder',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        transporteRepositoryProvider.overrideWithValue(repository),
        currentUserForTransportProvider.overrideWith((ref) async => UserModel(
              id: 7,
              nombre: 'Ana',
              apellidos: 'Ramis',
              email: 'ana@test.com',
              role: 'conductor',
            )),
        vehiculosDisponiblesProvider.overrideWith((ref) async => [
              {
                'id': 5,
                'placa': 'TEST',
                'marca': 'Volvo',
                'modelo': 'FH',
                'estado': 'disponible',
              }
            ]),
      ],
      child: const MaterialApp(home: Scaffold(body: RegistroAccionForm())),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TEST - Volvo FH').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1/2'));
    await tester.tap(find.text('1/2'));
    await tester.pumpAndSettle();

    final action = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reporte de Incidencias u Observaciones').last);
    await tester.pumpAndSettle();
    expect(find.text('Formulario en construcción para esta acción.'),
        findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Observaciones (Opcional)'),
      'Ruido en el motor',
    );
    final submit = find.text('Registrar Acción');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repository.submitted?.accionTipo,
        'Reporte de Incidencias u Observaciones');
    expect(repository.submitted?.observaciones, 'Ruido en el motor');
    expect(repository.submitted?.nivelCombustible, 50);

    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inspección Técnica').last);
    await tester.pumpAndSettle();
    expect(find.text('Formulario en construcción para esta acción.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Los datos globales permanecen al cambiar de acción',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        transporteRepositoryProvider.overrideWithValue(repository),
        currentUserForTransportProvider.overrideWith((ref) async => UserModel(
              id: 7,
              nombre: 'Ana',
              apellidos: 'Ramis',
              email: 'ana@test.com',
              role: 'conductor',
            )),
        vehiculosDisponiblesProvider.overrideWith((ref) async => [
              {
                'id': 5,
                'placa': 'TEST',
                'marca': 'Volvo',
                'modelo': 'FH',
                'estado': 'disponible',
              }
            ]),
      ],
      child: const MaterialApp(home: Scaffold(body: RegistroAccionForm())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Vehículo'), findsOneWidget);
    expect(find.text('Fecha del Registro'), findsOneWidget);
    expect(find.text('Nombre del Registrador'), findsOneWidget);
    expect(find.text('Ana Ramis'), findsOneWidget);
    expect(find.text('Kilometraje Inicial'), findsOneWidget);
    expect(find.byType(FuelGaugeSelector), findsOneWidget);
    expect(find.text('ACCIÓN A REALIZAR'), findsOneWidget);
    expect(find.text('Observaciones (Opcional)'), findsOneWidget);
    expect(find.text('Registrar Acción'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TEST - Volvo FH').last);
    await tester.pumpAndSettle();
    expect(find.text('125.0'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.descendant(
            of: find.widgetWithText(TextFormField, 'Kilometraje Inicial'),
            matching: find.byType(TextField),
          ))
          .readOnly,
      isTrue,
    );
    await tester.ensureVisible(find.text('1/4'));
    await tester.tap(find.text('1/4'));
    await tester.pumpAndSettle();

    final action = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operar Grúa').last);
    await tester.pumpAndSettle();
    expect(find.byType(FuelGaugeSelector), findsOneWidget);
    expect(find.text('125.0'), findsOneWidget);

    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mantenimiento Preventivo / Correctivo').last);
    await tester.pumpAndSettle();
    expect(find.byType(FuelGaugeSelector), findsOneWidget);
    expect(find.text('125.0'), findsOneWidget);

    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operar Grúa').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ACTIVIDAD A REALIZAR'),
      'Izaje',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'HORÓMETRO INICIAL'),
      '10.5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'HORÓMETRO FINAL'),
      '11.5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Observaciones (Opcional)'),
      'Sin novedad',
    );
    final submit = find.text('Registrar Acción');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.submitted?.vehiculoId, 5);
    expect(repository.submitted?.nivelCombustible, 25);
    expect(repository.submitted?.accionTipo, 'Operar Grúa');
    expect(repository.submitted?.observaciones, 'Sin novedad');
    expect(repository.submitted?.detallesGrua?.actividad, 'Izaje');
    expect(tester.takeException(), isNull);
  });

  testWidgets('La ruta Otras pide detalle y el checklist cabe en móvil',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        vehiculosDisponiblesProvider.overrideWith((ref) async => []),
        currentUserForTransportProvider.overrideWith((ref) async => UserModel(
              id: 7,
              nombre: 'Ana',
              apellidos: 'Ramis',
              email: 'ana@test.com',
              role: 'conductor',
            )),
      ],
      child: const MaterialApp(
        home: Scaffold(body: RegistroAccionForm()),
      ),
    ));

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empezar a Conducir').last);
    await tester.pumpAndSettle();

    final routeDropdown = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(routeDropdown);
    await tester.tap(routeDropdown);
    await tester.pumpAndSettle();
    expect(find.text('Ruta Juliaca a Arequipa (Viceversa)'), findsWidgets);
    await tester.tap(find.text('Otras').last);
    await tester.pumpAndSettle();

    expect(find.text('Especifique la ruta'), findsOneWidget);
    expect(
        find.text(
            'Documentos en vigencia (Soat, Rev.Tec., Tarjeta propiedad, licencia)'),
        findsOneWidget);
    final form = tester.state<FormState>(find.byType(Form));
    form.validate();
    await tester.pump();
    expect(find.text('Ingrese la ruta o recorrido'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Especifique la ruta'),
      'Ruta hacia campamento',
    );
    form.validate();
    await tester.pump();
    expect(find.text('Ingrese la ruta o recorrido'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
