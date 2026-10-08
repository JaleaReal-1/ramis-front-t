import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class CocadaFormWidget extends StatefulWidget {
  const CocadaFormWidget({super.key, required this.onChanged});

  final ValueChanged<AccionCocadaRequest?> onChanged;

  @override
  State<CocadaFormWidget> createState() => _CocadaFormWidgetState();
}

class _CocadaFormWidgetState extends State<CocadaFormWidget> {
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
        decoration: AppTheme.inputDecoration.copyWith(labelText: 'COCADA'),
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
              medida == null ? null : AccionCocadaRequest(medida: medida));
        },
      );
}
