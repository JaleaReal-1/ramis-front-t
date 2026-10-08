import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/registro_accion_form.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

void main() {
  testWidgets('La ruta Otras pide detalle y el checklist cabe en móvil',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        vehiculosDisponiblesProvider.overrideWith((ref) async => []),
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
