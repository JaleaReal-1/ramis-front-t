import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class MantenimientoFormWidget extends StatefulWidget {
  final void Function(AccionMantenimientoRequest) onChanged;

  const MantenimientoFormWidget({super.key, required this.onChanged});

  @override
  State<MantenimientoFormWidget> createState() =>
      _MantenimientoFormWidgetState();
}

class _MantenimientoFormWidgetState extends State<MantenimientoFormWidget> {
  String? _taller;
  String _tipo = 'Preventivo';

  final Map<String, bool> _preventivos = {
    "Mantenimiento General": false,
    "Cambio de llantas": false,
    "Reparaciones y/o Revisiones": false,
    "Lavado": false,
    "Certificación de Operatividad": false,
  };

  final _correctivoController = TextEditingController();

  @override
  void dispose() {
    _correctivoController.dispose();
    super.dispose();
  }

  void _emit() {
    List<String>? seleccionados;
    if (_tipo == 'Preventivo') {
      seleccionados =
          _preventivos.entries.where((e) => e.value).map((e) => e.key).toList();
    }

    widget.onChanged(AccionMantenimientoRequest(
      taller: _taller,
      tipo: _tipo,
      trabajosPreventivos: seleccionados,
      descripcionCorrectivo:
          _tipo == 'Correctivo' ? _correctivoController.text : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: 'NOMBRE DE EMPRESA TALLER',
          ),
          items: const [
            DropdownMenuItem(value: "CONAUTO", child: Text("CONAUTO")),
            DropdownMenuItem(value: "PERUMOTOR", child: Text("PERUMOTOR")),
            DropdownMenuItem(value: "MALVEX", child: Text("MALVEX")),
          ],
          onChanged: (val) {
            setState(() => _taller = val);
            _emit();
          },
          validator: (value) => value == null ? 'Seleccione un taller' : null,
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text('TIPO DE MANTENIMIENTO', style: AppTheme.bodyMedium),
        RadioGroup<String>(
          groupValue: _tipo,
          onChanged: (val) {
            if (val == null) return;
            setState(() => _tipo = val);
            _emit();
          },
          child: const Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Preventivo'),
                  value: 'Preventivo',
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Correctivo'),
                  value: 'Correctivo',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        if (_tipo == 'Preventivo') ...[
          FormField<bool>(
            validator: (_) => _preventivos.values.any((selected) => selected)
                ? null
                : 'Seleccione al menos un trabajo preventivo',
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._preventivos.keys.map((key) => CheckboxListTile(
                      title: Text(key),
                      value: _preventivos[key],
                      onChanged: (val) {
                        setState(() => _preventivos[key] = val ?? false);
                        field.didChange(true);
                        _emit();
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
                if (field.hasError)
                  Text(field.errorText!,
                      style:
                          AppTheme.bodySmall.copyWith(color: AppTheme.error)),
              ],
            ),
          ),
        ] else ...[
          TextFormField(
            controller: _correctivoController,
            decoration: AppTheme.inputDecoration.copyWith(
              labelText:
                  'CORRECTIVO: Describir el mantenimiento correctivo realizado...',
            ),
            maxLines: 3,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Describa el mantenimiento correctivo'
                : null,
            onChanged: (_) => _emit(),
          ),
        ]
      ],
    );
  }
}
