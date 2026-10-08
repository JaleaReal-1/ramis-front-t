import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class InspeccionFormWidget extends StatefulWidget {
  const InspeccionFormWidget({super.key, required this.onChanged});

  final ValueChanged<AccionInspeccionRequest?> onChanged;

  @override
  State<InspeccionFormWidget> createState() => _InspeccionFormWidgetState();
}

class _InspeccionFormWidgetState extends State<InspeccionFormWidget> {
  DateTime? _inspeccion;
  DateTime? _vencimiento;

  void _emit() {
    widget.onChanged(_inspeccion == null || _vencimiento == null
        ? null
        : AccionInspeccionRequest(
            fechaInspeccion: _inspeccion!,
            fechaVencimiento: _vencimiento!,
          ));
  }

  Future<void> _seleccionarFecha({
    required DateTime? actual,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (seleccionada != null && mounted) {
      onSelected(seleccionada);
      _emit();
    }
  }

  Widget _campoFecha({
    required String etiqueta,
    required DateTime? valor,
    required ValueChanged<DateTime> onSelected,
  }) {
    return FormField<DateTime>(
      validator: (_) => valor == null ? 'Seleccione una fecha' : null,
      builder: (field) => InkWell(
        onTap: () => _seleccionarFecha(
          actual: valor,
          onSelected: (fecha) {
            setState(() => onSelected(fecha));
            field.didChange(fecha);
          },
        ),
        child: InputDecorator(
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: etiqueta,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            errorText: field.errorText,
          ),
          child: Text(valor == null
              ? 'Seleccionar fecha'
              : '${valor.day.toString().padLeft(2, '0')}/'
                  '${valor.month.toString().padLeft(2, '0')}/${valor.year}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campoFecha(
          etiqueta: 'FECHA DE INSPECCIÓN TÉCNICA',
          valor: _inspeccion,
          onSelected: (fecha) => _inspeccion = fecha,
        ),
        const SizedBox(height: AppTheme.spacingL),
        _campoFecha(
          etiqueta: 'FECHA DE VENCIMIENTO DE INSPECCIÓN TÉCNICA',
          valor: _vencimiento,
          onSelected: (fecha) => _vencimiento = fecha,
        ),
      ],
    );
  }
}
