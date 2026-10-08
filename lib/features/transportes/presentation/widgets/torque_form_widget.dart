import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class TorqueFormWidget extends StatefulWidget {
  const TorqueFormWidget({super.key, required this.onChanged});

  final ValueChanged<AccionTorqueRequest?> onChanged;

  @override
  State<TorqueFormWidget> createState() => _TorqueFormWidgetState();
}

class _TorqueFormWidgetState extends State<TorqueFormWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _numero(String value) => double.tryParse(value.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: _controller,
        decoration: AppTheme.inputDecoration.copyWith(labelText: 'TORQUE'),
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        validator: (value) => _numero(value ?? '') == null
            ? 'Ingrese una medición numérica'
            : null,
        onChanged: (value) {
          final medida = _numero(value);
          widget.onChanged(
              medida == null ? null : AccionTorqueRequest(medida: medida));
        },
      );
}
