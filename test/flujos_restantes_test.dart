import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/cocada_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/inspeccion_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/torque_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/trabajos_externos_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/dynamic_actions/mantenimiento_form_widget.dart';

void main() {
  testWidgets('Inspección requiere las dos fechas y las emite', (tester) async {
    final key = GlobalKey<FormState>();
    AccionInspeccionRequest? detalle;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: key,
          child: InspeccionFormWidget(onChanged: (value) => detalle = value),
        ),
      ),
    ));
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    await tester.tap(find.text('Seleccionar fecha').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(detalle, isNull);
    await tester.tap(find.text('Seleccionar fecha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(key.currentState!.validate(), isTrue);
    expect(detalle?.toJson()['fecha_inspeccion'],
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(detalle?.toJson()['fecha_vencimiento'], isNotNull);
  });

  testWidgets('Cocada y torque aceptan medidas decimales', (tester) async {
    final key = GlobalKey<FormState>();
    AccionCocadaRequest? cocada;
    AccionTorqueRequest? torque;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: key,
          child: Column(
            children: [
              CocadaFormWidget(onChanged: (value) => cocada = value),
              TorqueFormWidget(onChanged: (value) => torque = value),
            ],
          ),
        ),
      ),
    ));
    expect(key.currentState!.validate(), isFalse);
    await tester.enterText(find.widgetWithText(TextFormField, 'COCADA'), '7,5');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'TORQUE'), '120.25');
    expect(key.currentState!.validate(), isTrue);
    expect(cocada?.toJson()['medida'], 7.5);
    expect(torque?.toJson()['medida'], 120.25);
  });

  testWidgets('Trabajos externos exige descripción', (tester) async {
    final key = GlobalKey<FormState>();
    AccionTrabajosExternosRequest? detalle;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: key,
          child: TrabajosExternosFormWidget(
            onChanged: (value) => detalle = value,
          ),
        ),
      ),
    ));
    expect(key.currentState!.validate(), isFalse);
    await tester.enterText(find.widgetWithText(TextFormField, 'TRABAJOS'),
        'Traslado de materiales');
    expect(key.currentState!.validate(), isTrue);
    expect(detalle?.toJson()['descripcion_trabajos'], 'Traslado de materiales');
  });

  test('El payload incluye los cuatro detalles nuevos', () {
    final request = RegistroAccionRequest(
      accionTipo: 'Inspección Técnica',
      vehiculoId: 3,
      nivelCombustible: 50,
      observaciones: 'Sin novedad',
      detallesInspeccion: AccionInspeccionRequest(
        fechaInspeccion: DateTime(2026, 10, 8),
        fechaVencimiento: DateTime(2027, 10, 8),
      ),
      detallesCocada: const AccionCocadaRequest(medida: 7.5),
      detallesTorque: const AccionTorqueRequest(medida: 120.25),
      detallesTrabajosExternos: const AccionTrabajosExternosRequest(
        descripcionTrabajos: 'Traslado de materiales',
      ),
    );
    final json = request.toJson();
    expect(json['detalles_inspeccion']['fecha_inspeccion'], '2026-10-08');
    expect(json['detalles_cocada']['medida'], 7.5);
    expect(json['detalles_torque']['medida'], 120.25);
    expect(json['detalles_trabajos_externos']['descripcion_trabajos'],
        'Traslado de materiales');
  });

  testWidgets('Mantenimiento admite taller y trabajo preventivo Otros',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<FormState>();
    AccionMantenimientoRequest? detalle;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            key: key,
            child: MantenimientoFormWidget(
              onChanged: (value) => detalle = value,
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otros').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Especifique el taller'),
        'Taller local');
    await tester.ensureVisible(find.widgetWithText(CheckboxListTile, 'Otros'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Otros'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Otro trabajo realizado'),
        'Cambio de filtro');
    expect(key.currentState!.validate(), isTrue);
    expect(detalle?.taller, 'Taller local');
    expect(detalle?.trabajosPreventivos, contains('Cambio de filtro'));
    expect(tester.takeException(), isNull);
  });
}
