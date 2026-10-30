import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_ocs/data/models/user_model.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/documento_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/conductor_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/conductores_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/documentos_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/vehiculo_detalle_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/observacion_fields.dart';
import 'package:sistema_ocs/features/transportes/providers/documentos_provider.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

class _Repo extends TransporteRepositoryImpl {
  _Repo() : super(Dio());
  Map<String, dynamic>? carga;
  String? correo;
  @override
  Future<dynamic> getV3(String path) async => [];
  @override
  Future<bool> subirDocumento(String entidad, int id,
      Map<String, dynamic> fields, List<int> bytes, String name) async {
    carga = {'entidad': entidad, 'id': id, ...fields};
    return false;
  }

  @override
  Future<void> configurarAcceso(int id, String email, String password) async {
    correo = email;
  }
}

const titular = (entidad: 'conductor', id: 7);
final rows = documentosConductor.keys
    .map((tipo) => DocumentoTransporte.fromJson({
          'tipo': tipo,
          'documento_id': 10,
          'estado_documento': 'pendiente',
          'semaforo': 'amarillo',
          'licencia_categoria': 'A-IIb',
          'fecha_vencimiento': '2026-11-10',
          'dias_restantes': 20,
        }))
    .toList();

void main() {
  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('La tercera pestaña muestra los tres documentos en un teléfono',
      (tester) async {
    await phone(tester);
    final repo = _Repo();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          transporteRepositoryProvider.overrideWithValue(repo),
          currentUserForTransportProvider.overrideWith((ref) async => UserModel(
              id: 7,
              nombre: 'Ana',
              apellidos: 'Ramis',
              email: 'ana@test.com',
              role: 'conductor')),
          miJornadaProvider.overrideWith((ref) async => null),
          accionesRegistradasProvider.overrideWith((ref) async => []),
          documentosProvider(titular).overrideWith((ref) async => rows),
        ],
        child:
            const MaterialApp(home: ConductorJornadaScreen(initialIndex: 2))));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Licencia de Conducir'), findsOneWidget);
    expect(find.text('Categoría: A-IIb'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('Pase Minero San Rafael / Minsur'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Pase Minero San Rafael / Minsur'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Carga desde galería conserva campos y confirma guardado offline',
      (tester) async {
    await phone(tester);
    final repo = _Repo();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          transporteRepositoryProvider.overrideWithValue(repo),
          documentosProvider(titular).overrideWith((ref) async => rows),
          elegirFotoProvider.overrideWithValue((source) async => XFile.fromData(
              base64Decode(
                  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWQAAAABJRU5ErkJggg=='),
              name: 'licencia.png')),
        ],
        child: const MaterialApp(
            home: DocumentosScreen(entidad: 'conductor', titularId: 7))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subir documento').first);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoría de licencia'), 'A-IIb');
    await tester.tap(find.text('Elegir fecha de vencimiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galería'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enviar documento'));
    await tester.tap(find.text('Enviar documento'));
    await tester.pumpAndSettle();
    expect(repo.carga?['tipo'], 'licencia');
    expect(repo.carga?['licencia_categoria'], 'A-IIb');
    expect(find.textContaining('Documento guardado sin conexión.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Administración configura acceso con validaciones en 360 px',
      (tester) async {
    await phone(tester);
    final repo = _Repo();
    await tester.pumpWidget(ProviderScope(overrides: [
      transporteRepositoryProvider.overrideWithValue(repo),
      conductoresV3Provider.overrideWith((ref) async => [
            {
              'id': 7,
              'nombre': 'Ana',
              'apellidos': 'Ramis',
              'dni': '12345678',
              'email': 'old@test.com',
              'documentos': []
            }
          ]),
    ], child: const MaterialApp(home: ConductoresScreen())));
    await tester.pumpAndSettle();
    expect(find.text('DNI: 12345678'), findsOneWidget);
    await tester.tap(find.text('Configurar Acceso'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'ana@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña inicial'),
        'ClaveSegura123');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.correo, 'ana@test.com');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Detalle del vehículo presenta cinco documentos y el PDF',
      (tester) async {
    await phone(tester);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          transporteRepositoryProvider.overrideWithValue(_Repo()),
          documentosProvider((entidad: 'vehiculo', id: 9))
              .overrideWith((ref) async => []),
        ],
        child: MaterialApp(
            home: VehiculoDetalleScreen(vehiculo: const {
          'id': 9,
          'placa': 'ABC-123',
          'marca': 'Ramis',
          'modelo': 'Camión',
          'kilometraje_actual': 100,
          'estado_semaforo': 'verde'
        }))));
    await tester.pumpAndSettle();
    expect(find.text('Descargar Ficha Técnica PDF'), findsOneWidget);
    expect(find.text('SOAT'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pase Minero de Unidad'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Pase Minero de Unidad'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
