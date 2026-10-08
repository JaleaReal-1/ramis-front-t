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
  final _otroTallerController = TextEditingController();
  final _otroTrabajoController = TextEditingController();

  final Map<String, bool> _preventivos = {
    "Mantenimiento General": false,
    "Cambio de llantas": false,
    "Reparaciones y/o Revisiones": false,
    "Lavado": false,
    "Certificación de Operatividad": false,
    "Otros": false,
  };

  final _correctivoController = TextEditingController();

  @override
  void dispose() {
    _correctivoController.dispose();
    _otroTallerController.dispose();
    _otroTrabajoController.dispose();
    super.dispose();
  }

  void _emit() {
    List<String>? seleccionados;
    if (_tipo == 'Preventivo') {
      seleccionados = _preventivos.entries
          .where((e) => e.value && e.key != 'Otros')
          .map((e) => e.key)
          .toList();
      if (_preventivos['Otros'] == true &&
          _otroTrabajoController.text.trim().isNotEmpty) {
        seleccionados.add(_otroTrabajoController.text.trim());
      }
    }

    widget.onChanged(AccionMantenimientoRequest(
      taller: _taller == 'Otros' ? _otroTallerController.text.trim() : _taller,
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
            labelText: 'NOMBRE DE EMPRESA TALLER O CONCESIONARIA',
          ),
          items: const [
            DropdownMenuItem(value: "CONAUTO", child: Text("CONAUTO")),
            DropdownMenuItem(value: "PERUMOTOR", child: Text("PERUMOTOR")),
            DropdownMenuItem(value: "MALVEX", child: Text("MALVEX")),
            DropdownMenuItem(value: "Otros", child: Text("Otros")),
          ],
          onChanged: (val) {
            setState(() => _taller = val);
            _emit();
          },
          validator: (value) => value == null ? 'Seleccione un taller' : null,
        ),
        if (_taller == 'Otros') ...[
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _otroTallerController,
            decoration: AppTheme.inputDecoration.copyWith(
              labelText: 'Especifique el taller',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingrese el nombre del taller'
                : null,
            onChanged: (_) => _emit(),
          ),
        ],
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Llenar al momento de recoger el vehículo del taller de mantenimiento',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.spacingS),
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
                ? (_preventivos['Otros'] == true &&
                        _otroTrabajoController.text.trim().isEmpty
                    ? 'Describa el otro trabajo preventivo'
                    : null)
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
                if (_preventivos['Otros'] == true)
                  TextFormField(
                    controller: _otroTrabajoController,
                    decoration: AppTheme.inputDecoration.copyWith(
                      labelText: 'Otro trabajo realizado',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Describa el otro trabajo preventivo'
                        : null,
                    onChanged: (_) {
                      field.didChange(true);
                      _emit();
                    },
                  ),
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
              helperText: 'Tomar referencia del informe del mantenimiento',
              helperMaxLines: 2,
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
