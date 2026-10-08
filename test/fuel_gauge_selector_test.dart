import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/fuel_gauge_selector.dart';

void main() {
  testWidgets('El selector de combustible cabe en una pantalla estrecha',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(240, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    int? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: FuelGaugeSelector(
            value: 50,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('1/4'));
    expect(selected, 25);
  });
}
