// Export the actual production widgets, without changing their layout or theme.
// Run: flutter test tool/figma_capture_test.dart --concurrency=1
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'figma_vector_export.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/user_model.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/conductor_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/admin_transportes_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/asignacion_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/registro_accion_form.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/observacion_fields.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';
import 'package:sistema_ocs/features/transportes/providers/admin_transportes_provider.dart';

class CaptureRepo extends TransporteRepositoryImpl {
  CaptureRepo() : super(Dio());
  String color = 'verde';
  String state = 'en_curso';
  bool empty = false;
  bool closed = false;
  Map<String, dynamic> vehicle(int id, String semaforo) => {
        'id': id,
        'placa': id == 5
            ? 'Z7F-777'
            : id == 6
                ? 'Z7G-937'
                : 'Z7H-938',
        'marca': 'Hino',
        'modelo': 'Camión Grúa',
        'tipo': 'Camión Grúa',
        'estado': semaforo == 'rojo' ? 'en_mantenimiento' : 'disponible',
        'estado_semaforo': semaforo,
        'kilometraje_actual': 45210.0,
        'capacidad_tanque_galones': 40.0,
        if (semaforo != 'verde')
          'observaciones_pendientes': 'Mica pendiente de revisión',
      };
  JornadaTransporte get current => JornadaTransporte(
        id: 104,
        conductorId: 7,
        vehiculoId: 5,
        estado: closed ? 'finalizada' : state,
        accionTipo: 'Empezar a Conducir',
        kmInicial: 45210,
        kmFinal: closed ? 45310 : null,
        nivelCombustible: 75,
        estadoSemaforo: color,
        fechaInicio: DateTime.now().copyWith(hour: 8, minute: 30),
        observaciones:
            color == 'verde' ? 'Sin novedades' : 'Mica pendiente de revisión',
        galonesConsumidos: closed ? 10 : null,
        rendimientoKmGalon: closed ? 10 : null,
        subAcciones: [action],
      );
  JornadaTransporte get action => JornadaTransporte(
        id: 105,
        conductorId: 7,
        vehiculoId: 5,
        estado: 'finalizada',
        jornadaPadreId: 104,
        accionTipo: 'Operar Grúa',
        kmInicial: 45210,
        fechaInicio: DateTime.now().copyWith(hour: 11, minute: 40),
        detallesGrua: const {
          'actividad': 'Izaje de materiales',
          'horometro_inicial': 1230,
          'horometro_final': 1232
        },
      );
  @override
  Future<List<JornadaTransporte>> listarJornadas() async =>
      empty ? [] : [current, action];
  @override
  Future<JornadaTransporte> obtenerJornada(int id) async =>
      id == 105 ? action : current;
  @override
  Future<Map<String, dynamic>> obtenerVehiculo(int id) async =>
      vehicle(id, color);
  @override
  Future<double> obtenerKilometrajeVehiculo(int id) async => 45210;
  @override
  Future<List<Map<String, dynamic>>> listarVehiculos() async =>
      [vehicle(5, 'verde'), vehicle(6, 'amarillo'), vehicle(8, 'rojo')];
  @override
  Future<List<Map<String, dynamic>>> listarTrabajadores() async => [
        {
          'id': 7,
          'nombre': 'Conductor',
          'apellidos': 'Demo',
          'role': 'conductor'
        }
      ];
  @override
  Future<JornadaTransporte> registrarChecklistFinal(
      int id, ChecklistRequest request) async {
    closed = true;
    return current;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Exportar pantallas reales de Transportes para Figma',
      (tester) async {
    await tester.runAsync(() async {
      final root =
          Platform.environment['FLUTTER_ROOT'] ?? r'C:\Users\Jalea\flutter';
      final loader = FontLoader('Roboto');
      for (final name in ['regular', 'medium', 'bold', 'black']) {
        final bytes = await File(
                '$root/bin/cache/artifacts/material_fonts/roboto-$name.ttf')
            .readAsBytes();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(Future.value(ByteData.sublistView(await File(
              '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf')
          .readAsBytes())));
      await icons.load();
    });
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    var serial = 0;
    var repo = CaptureRepo();
    Future<void> mount(Widget home,
        {bool admin = false,
        bool loading = false,
        bool error = false,
        bool adminEmpty = false}) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(ProviderScope(
          key: ValueKey(serial++),
          overrides: [
            transporteRepositoryProvider.overrideWithValue(repo),
            currentUserForTransportProvider.overrideWith((ref) async =>
                UserModel(
                    id: 7,
                    nombre: 'Conductor',
                    apellidos: 'Demo',
                    email: 'demo@example.invalid',
                    role: admin ? 'admin' : 'conductor')),
            if (loading)
              miJornadaProvider.overrideWith(
                  (ref) => Completer<JornadaTransporte?>().future),
            if (error)
              miJornadaProvider
                  .overrideWith((ref) => Future.error('Sin conexión')),
            if (adminEmpty)
              jornadasListProvider.overrideWith((ref) async => []),
            if (adminEmpty)
              vehiculosListProvider.overrideWith((ref) async => []),
            if (adminEmpty)
              mantenimientosListProvider.overrideWith((ref) async => []),
            if (!adminEmpty)
              mantenimientosListProvider.overrideWith((ref) async => [
                    {
                      'id': 1,
                      'vehiculo_id': 5,
                      'tipo': 'Preventivo',
                      'estado': 'pendiente',
                      'descripcion': 'Mantenimiento General'
                    }
                  ]),
            if (loading)
              jornadasListProvider.overrideWith(
                  (ref) => Completer<List<Map<String, dynamic>>>().future),
            if (error)
              jornadasListProvider
                  .overrideWith((ref) => Future.error('Sin conexión')),
          ],
          child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  home: home))));
      if (loading) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      } else {
        await tester.pumpAndSettle();
      }
    }

    Future<void> shot(String id) async {
      await tester.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      Future<void> write(String filename) async {
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('../docs/figma_transportes/capturas/$filename.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
          await exportEditableFrame(boundary, filename);
        });
      }

      await write(id);
      if (!['C03', 'C31', 'A12'].contains(id)) {
        final scrolls = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .where((s) =>
                s.position.hasContentDimensions &&
                s.position.maxScrollExtent > 0 &&
                s.position.viewportDimension > 180)
            .toList();
        if (scrolls.isNotEmpty) {
          final position = scrolls.last.position,
              original = scrolls.last.position.pixels;
          var part = 2;
          // Include all scroll positions while retaining the first selected view.
          for (double offset = 0;
              offset <= position.maxScrollExtent + 1;
              offset += position.viewportDimension * 0.8) {
            final target = offset.clamp(0.0, position.maxScrollExtent);
            if ((target - original).abs() < 20) continue;
            position.jumpTo(target);
            await tester.pumpAndSettle();
            await write('${id}__${part.toString().padLeft(2, '0')}');
            part++;
          }
          if ((position.pixels - position.maxScrollExtent).abs() > 20) {
            position.jumpTo(position.maxScrollExtent);
            await tester.pumpAndSettle();
            await write('${id}__${part.toString().padLeft(2, '0')}');
          }
          position.jumpTo(original);
          await tester.pumpAndSettle();
        }
      }
      final exception = tester.takeException();
      if (id == 'C32' || id == 'A13') {
        expect(exception == null || exception.toString() == 'Sin conexión',
            isTrue);
      } else {
        expect(exception, isNull, reason: id);
      }
    }

    Future<void> tapText(String value) async {
      final f = find.text(value).last;
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> dropdown(Finder f, String value) async {
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
      await tapText(value);
    }

    Future<void> conductor(
        {bool noJourney = false,
        String color = 'verde',
        String state = 'en_curso'}) async {
      repo = CaptureRepo()
        ..empty = noJourney
        ..color = color
        ..state = state;
      await mount(const ConductorJornadaScreen());
    }

    Future<void> form({bool opening = false}) async {
      repo = CaptureRepo();
      await mount(Scaffold(
          appBar: AppBar(
              title: Text(opening ? 'Abrir jornada' : 'Sub-acción en ruta')),
          body: RegistroAccionForm(
              soloApertura: opening, jornada: opening ? null : repo.current)));
    }

    Future<void> action(String value) async {
      await dropdown(find.byType(DropdownButtonFormField<String>).first, value);
    }

    Future<void> adminTab(String tab, {bool empty = false}) async {
      repo = CaptureRepo()..color = 'amarillo';
      await mount(const AdminTransportesScreen(),
          admin: true, adminEmpty: empty);
      if (tab != 'Jornadas') await tapText(tab);
    }

    await conductor(noJourney: true);
    await shot('C01');
    await tapText('Empezar a Conducir');
    await shot('C02');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await shot('C03');
    await tapText('Z7F-777 - Hino Camión Grúa');
    await dropdown(find.byType(DropdownButtonFormField<String>).last, 'Otras');
    await shot('C04');
    await tester.ensureVisible(find.text('Check List Flash (Obligatorio)'));
    await tester.pumpAndSettle();
    await shot('C05');
    await conductor(state: 'pendiente');
    await shot('C06');
    await tapText('Checklist de apertura');
    await shot('C33');
    for (final entry
        in {'C07': 'verde', 'C08': 'amarillo', 'C09': 'rojo'}.entries) {
      await conductor(color: entry.value);
      await shot(entry.key);
    }
    await conductor();
    await tapText('Reportar Observación');
    await shot('C10');
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await shot('C11');
    await dropdown(find.byType(DropdownButtonFormField<String>),
        'Grave / Crítica · Vehículo inoperativo');
    await shot('C12');
    await form();
    await shot('C13');
    for (final entry in {
      'C14': 'Operar Grúa',
      'C15': 'Abastecer Combustible',
      'C16': 'Mantenimiento Preventivo / Correctivo',
      'C19': 'Inspección Técnica',
      'C20': 'Medición de Cocada',
      'C21': 'Medición de Torque',
      'C22': 'Trabajos a Externos',
      'C23': 'Check List y/o V°B° de vehículos'
    }.entries) {
      await form();
      await action(entry.value);
      await shot(entry.key);
      if (entry.key == 'C16') {
        await tapText('Correctivo');
        await shot('C17');
        await tapText('Preventivo');
        final other = find.widgetWithText(CheckboxListTile, 'Otros');
        await tester.ensureVisible(other);
        await tester.tap(other);
        await tester.pumpAndSettle();
        await shot('C18');
      }
    }
    await conductor();
    await tapText('Finalizar Jornada');
    await shot('C24');
    await tester.ensureVisible(find.text('Conforme'));
    await tester.tap(find.widgetWithText(SwitchListTile, 'Conforme'));
    await tester.pumpAndSettle();
    await shot('C25');
    await conductor();
    await tapText('Finalizar Jornada');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Odómetro Final (km)'), '45310');
    await dropdown(find.byType(DropdownButtonFormField<String>), '1/2');
    await tapText('Confirmar y Finalizar Jornada');
    await shot('C26');
    await conductor(noJourney: true);
    await tapText('Historial');
    await shot('C27');
    await conductor();
    await tapText('Historial');
    await shot('C28');
    await tapText('Operar Grúa');
    await shot('C29');
    await mount(Scaffold(
        appBar: AppBar(title: const Text('Historial de jornadas')),
        body: const FotoObservacion(
            url: '/uploads/transportes/evidencia-no-disponible.jpg')));
    await tester.tap(find.byType(FotoObservacion));
    await tester.pumpAndSettle();
    await shot('C30');
    await conductor();
    await mount(const ConductorJornadaScreen(), loading: true);
    await shot('C31');
    await mount(const ConductorJornadaScreen(), error: true);
    await shot('C32');
    await form(opening: true);
    await tapText('Registrar Acción');
    await shot('C34');
    repo = CaptureRepo();
    await mount(const AsignacionJornadaScreen(), admin: true);
    await shot('A01');
    await dropdown(find.byType(DropdownButtonFormField<int>).first,
        'Z7G-937 - Hino Camión Grúa');
    await shot('A02');
    await adminTab('Jornadas');
    await shot('A03');
    await tapText('Jornada #104 - Conductor ID: 7');
    await shot('A04');
    await adminTab('Flota');
    await shot('A05');
    await tapText('Z7F-777 - Hino Camión Grúa');
    await shot('A06');
    await adminTab('Observaciones');
    await shot('A07');
    await tapText('Jornada #104 · Vehículo #5');
    await shot('A08');
    await adminTab('Mantenimientos');
    await shot('A09');
    await adminTab('GPS');
    await shot('A10');
    for (final entry in {
      'A11': 'Jornadas',
      'A14': 'Flota',
      'A15': 'Observaciones',
      'A16': 'Mantenimientos'
    }.entries) {
      await adminTab(entry.value, empty: true);
      await shot(entry.key);
    }
    await mount(const AdminTransportesScreen(), admin: true, loading: true);
    await shot('A12');
    await mount(const AdminTransportesScreen(), admin: true, error: true);
    await shot('A13');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    debugDisableShadows = true;
  });
}
