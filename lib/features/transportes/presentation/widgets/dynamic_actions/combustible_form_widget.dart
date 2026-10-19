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
  final _costoController = TextEditingController();
  final _comprobanteController = TextEditingController();

  @override
  void dispose() {
    _galonesController.dispose();
    _costoController.dispose();
    _comprobanteController.dispose();
    super.dispose();
  }

  double? _galones(String value) => double.tryParse(value.replaceAll(',', '.'));

  void _emit() {
    widget.onChanged(AccionCombustibleRequest(
      costo: _galones(_costoController.text),
      comprobante: _comprobanteController.text.trim(),
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
            controller: _costoController,
            decoration: const InputDecoration(labelText: 'Costo total (S/)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _emit(),
            validator: (v) => (v ?? '').isNotEmpty &&
                    (_galones(v!) == null || _galones(v)! < 0)
                ? 'Ingrese un costo válido'
                : null),
        TextFormField(
            controller: _comprobanteController,
            decoration: const InputDecoration(labelText: 'N° factura / vale'),
            maxLength: 100,
            onChanged: (_) => _emit()),
        TextFormField(
          controller: _galonesController,
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: 'CANTIDAD COMBUSTIBLE ABASTECIDO EN GALONES',
            helperText:
                'Colocar la cantidad de galones abastecidos en el grifo',
            helperMaxLines: 2,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final cantidad = _galones(value ?? '');
            return cantidad == null || cantidad < 0.1 || cantidad > 100
                ? 'Ingrese entre 0.1 y 100 galones'
                : null;
          },
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text('NIVEL DE COMBUSTIBLE FINAL', style: AppTheme.bodyMedium),
        Text('Colocar el nivel después de abastecer',
            style: AppTheme.bodySmall),
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
