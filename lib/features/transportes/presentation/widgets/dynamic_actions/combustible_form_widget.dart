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
  int? _nivelFinal;

  @override
  void dispose() {
    _galonesController.dispose();
    super.dispose();
  }

  double? _galones(String value) => double.tryParse(value.replaceAll(',', '.'));

  void _emit() {
    widget.onChanged(AccionCombustibleRequest(
      galones: _galones(_galonesController.text),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final cantidad = _galones(value ?? '');
            return cantidad == null || cantidad <= 0
                ? 'Ingrese una cantidad válida de galones'
                : null;
          },
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text('NIVEL DE COMBUSTIBLE FINAL', style: AppTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingS),
        FormField<int>(
          validator: (value) =>
              value == null ? 'Seleccione el nivel de combustible final' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FuelGaugeSelector(
                value: _nivelFinal,
                onChanged: (val) {
                  field.didChange(val);
                  setState(() => _nivelFinal = val);
                  _emit();
                },
              ),
              if (field.hasError)
                Text(field.errorText!,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
            ],
          ),
        ),
      ],
    );
  }
}
