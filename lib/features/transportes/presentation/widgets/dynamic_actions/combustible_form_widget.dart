import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/fuel_gauge_selector.dart';

class CombustibleFormWidget extends StatefulWidget {
  final void Function(AccionCombustibleRequest) onChanged;

  const CombustibleFormWidget({super.key, required this.onChanged});

  @override
  State<CombustibleFormWidget> createState() => _CombustibleFormWidgetState();
}

class _CombustibleFormWidgetState extends State<CombustibleFormWidget> {
  final _galonesController = TextEditingController();
  int _nivelFinal = 100;

  void _emit() {
    widget.onChanged(AccionCombustibleRequest(
      galones: double.tryParse(_galonesController.text),
      nivelFinal: _nivelFinal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _galonesController,
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: 'CANTIDAD COMBUSTIBLE ABASTECIDO EN GALONES',
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text('NIVEL DE COMBUSTIBLE FINAL', style: AppTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingS),
        FuelGaugeSelector(
          value: _nivelFinal,
          onChanged: (val) {
            setState(() => _nivelFinal = val);
            _emit();
          },
        ),
      ],
    );
  }
}
