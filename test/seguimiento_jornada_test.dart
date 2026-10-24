import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_ocs/data/models/user_model.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/conductor_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/observacion_fields.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/vehiculo_selector.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

class _Repo extends TransporteRepositoryImpl {
  _Repo() : super(Dio());
  bool roja = false;
  bool cerrada = false;
  RegistroAccionRequest? accion;
  ChecklistRequest? cierre;
  IncidenciaRutaRequest? reporte;
  JornadaTransporte get jornada => JornadaTransporte(
        id: 10,
        conductorId: 7,
        vehiculoId: 5,
        estado: cerrada ? 'finalizada' : 'en_curso',
        accionTipo: 'Empezar a Conducir',
        kmInicial: 5000,
        nivelCombustible: 75,
        fechaInicio: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        estadoSemaforo: roja ? 'rojo' : 'verde',
        incidencias: reporte == null
            ? []
            : [
                IncidenciaRuta(
                    id: 1,
                    jornadaId: 10,
                    tipo: 'falla',
                    descripcion: reporte!.descripcion,
                    severidad: reporte!.severidad,
                    fotoIncidencia: reporte!.fotoIncidencia,
                    fecha: DateTime.now().toUtc())
              ],
      );
  Map<String, dynamic> get vehiculo => {
        'id': 5,
        'placa': 'Z7F-777',
        'marca': 'Hino',
        'modelo': 'Camión Grúa',
        'tipo': 'Camión Grúa',
        'kilometraje_actual': 5000,
        'capacidad_tanque_galones': 40,
        'estado': roja ? 'en_mantenimiento' : 'en_ruta',
        'estado_semaforo': roja ? 'rojo' : 'verde'
      };
  @override
  Future<List<JornadaTransporte>> listarJornadas() async => [jornada];
  @override
  Future<JornadaTransporte> obtenerJornada(int id) async => jornada;
  @override
  Future<Map<String, dynamic>> obtenerVehiculo(int id) async => vehiculo;
  @override
  Future<List<Map<String, dynamic>>> listarVehiculos() async => [vehiculo];
  @override
  Future<String> subirFoto(List<int> bytes, String nombre) async =>
      '/uploads/transportes/abc.jpg';
  @override
  Future<IncidenciaRuta> registrarIncidencia(
      int id, IncidenciaRutaRequest request) async {
    reporte = request;
    roja = request.severidad == 'critica';
    return jornada.incidencias.first;
  }

  @override
  Future<JornadaTransporte> registrarAccion(
      RegistroAccionRequest request) async {
    accion = request;
    return JornadaTransporte(
        id: 11,
        conductorId: 7,
        vehiculoId: 5,
        estado: 'finalizada',
        jornadaPadreId: 10,
        accionTipo: 'Operar Grúa');
  }

  @override
  Future<JornadaTransporte> registrarChecklistFinal(
      int id, ChecklistRequest request) async {
    cierre = request;
    cerrada = true;
    return JornadaTransporte(
        id: 10,
        conductorId: 7,
        vehiculoId: 5,
        estado: 'finalizada',
        kmInicial: 5000,
        kmFinal: request.kilometraje,
        galonesConsumidos: 10,
        rendimientoKmGalon: 10);
  }
}

Future<void> _abrir(WidgetTester tester, _Repo repo) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ProviderScope(overrides: [
    transporteRepositoryProvider.overrideWithValue(repo),
    currentUserForTransportProvider.overrideWith((ref) async => UserModel(
        id: 7,
        nombre: 'Ana',
        apellidos: 'Ramis',
        email: 'ana@test.com',
        role: 'conductor')),
    elegirFotoProvider.overrideWithValue((source) async =>
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'foto.jpg')),
  ], child: const MaterialApp(home: ConductorJornadaScreen())));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Rojo deshabilitado y amarillo seleccionable con advertencia previa',
      (tester) async {
    int? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
                builder: (context, update) => VehiculoSelector(
                    value: selected,
                    vehiculos: const [
                      {
                        'id': 1,
                        'placa': 'VERDE',
                        'marca': 'Hino',
                        'modelo': 'Carga',
                        'estado': 'disponible',
                        'estado_semaforo': 'verde'
                      },
                      {
                        'id': 2,
                        'placa': 'AMARILLO',
                        'marca': 'Hino',
                        'modelo': 'Carga',
                        'estado': 'disponible',
                        'estado_semaforo': 'amarillo',
                        'observaciones_pendientes': 'Mica por revisar'
                      },
                      {
                        'id': 3,
                        'placa': 'ROJO',
                        'marca': 'Hino',
                        'modelo': 'Carga',
                        'estado': 'en_mantenimiento',
                        'estado_semaforo': 'rojo'
                      },
                    ],
                    onChanged: (v) =>
                        update(() => selected = v['id'] as int))))));
    final dropdown =
        tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>));
    expect(dropdown.items!.firstWhere((v) => v.value == 3).enabled, isFalse);
    expect(dropdown.items!.firstWhere((v) => v.value == 2).enabled, isTrue);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AMARILLO - Hino Carga').last);
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(find.textContaining('Mica por revisar'), findsOneWidget);
  });

  testWidgets(
      'Consola activa muestra vehículo, semáforo, odómetro inicial y timeline',
      (tester) async {
    await _abrir(tester, _Repo());
    expect(find.text('Mi jornada en curso'), findsOneWidget);
    expect(find.text('Z7F-777 · Camión Grúa'), findsOneWidget);
    expect(find.text('Odómetro inicial: 5000.0 km'), findsOneWidget);
    expect(find.text('Verde · Buen estado'), findsOneWidget);
    expect(find.text('Línea de tiempo de hoy'), findsOneWidget);
    expect(find.text('Finalizar Jornada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Reporte grave conserva consola abierta y habilita cierre explícito',
      (tester) async {
    final repo = _Repo();
    await _abrir(tester, repo);
    await tester.tap(find.text('Reportar Observación'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crítica · Vehículo inoperativo').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción detallada'),
        'Falla en frenos');
    await tester.ensureVisible(find.text('Galería'));
    await tester.tap(find.text('Galería'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar Observación (continuar jornada)'));
    await tester.pumpAndSettle();
    expect(repo.reporte?.severidad, 'critica');
    expect(repo.cerrada, isFalse);
    expect(find.text('Rojo · Vehículo inoperativo'), findsOneWidget);
    expect(find.text('Mi jornada en curso'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Finalizar Jornada'), 250);
    expect(find.text('Finalizar Jornada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Grúa solo usa horómetros y se envía con jornada padre sin km',
      (tester) async {
    final repo = _Repo();
    await _abrir(tester, repo);
    await tester.tap(find.text('Registrar Sub-Acción en Ruta'));
    await tester.pumpAndSettle();
    final action = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Empezar a Conducir'), findsNothing);
    await tester.tap(find.text('Operar Grúa').last);
    await tester.pumpAndSettle();
    expect(find.text('Odómetro al registrar la actividad'), findsNothing);
    expect(find.text('Odómetro Final (km)'), findsNothing);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'ACTIVIDAD A REALIZAR'), 'Izaje');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'HORÓMETRO INICIAL'), '10');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'HORÓMETRO FINAL'), '12');
    await tester.ensureVisible(find.text('Registrar Acción'));
    await tester.tap(find.text('Registrar Acción'));
    await tester.pumpAndSettle();
    expect(repo.accion?.jornadaPadreId, 10);
    expect(repo.accion?.toJson().containsKey('km_inicial'), isFalse);
    expect(repo.accion?.toJson().containsKey('nivel_combustible'), isFalse);
    expect(repo.accion?.detallesGrua?.horometroFinal, 12);
    expect(repo.cerrada, isFalse);
    expect(find.text('Mi jornada en curso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Finalizar Jornada solicita km y combustible y muestra liquidación',
      (tester) async {
    final repo = _Repo();
    await _abrir(tester, repo);
    await tester.ensureVisible(find.text('Finalizar Jornada'));
    await tester.tap(find.text('Finalizar Jornada'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Odómetro Final (km)'), '5100');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1/2').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Rendimiento: 10.00 km/gal'), findsOneWidget);
    await tester.ensureVisible(find.text('Confirmar y Finalizar Jornada'));
    await tester.tap(find.text('Confirmar y Finalizar Jornada'));
    await tester.pumpAndSettle();
    expect(repo.cierre?.kilometraje, 5100);
    expect(repo.cierre?.nivelCombustible, '50');
    expect(repo.cerrada, isTrue);
    expect(find.text('Jornada finalizada'), findsOneWidget);
    expect(find.text('Rendimiento: 10.00 km/gal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
