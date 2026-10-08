import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class MantenimientoFormWidget extends StatefulWidget {
  final void Function(AccionMantenimientoRequest) onChanged;

  const MantenimientoFormWidget({super.key, required this.onChanged});

  @override
  State<MantenimientoFormWidget> createState() => _MantenimientoFormWidgetState();
}

class _MantenimientoFormWidgetState extends State<MantenimientoFormWidget> {
  String? _taller;
  String? _tipo = 'Preventivo';
  
  final Map<String, bool> _preventivos = {
    "Mantenimiento General": false,
    "Cambio de llantas": false,
    "Reparaciones y/o Revisiones": false,
    "Lavado": false,
    "Certificación de Operatividad": false,
  };
  
  final _correctivoController = TextEditingController();

  void _emit() {
    List<String>? seleccionados;
    if (_tipo == 'Preventivo') {
      seleccionados = _preventivos.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
    }
    
    widget.onChanged(AccionMantenimientoRequest(
      taller: _taller,
      tipo: _tipo,
      trabajosPreventivos: seleccionados,
      descripcionCorrectivo: _tipo == 'Correctivo' ? _correctivoController.text : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
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
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text('TIPO DE MANTENIMIENTO', style: AppTheme.bodyMedium),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Preventivo'),
                value: 'Preventivo',
                groupValue: _tipo,
                onChanged: (val) {
                  setState(() => _tipo = val);
                  _emit();
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Correctivo'),
                value: 'Correctivo',
                groupValue: _tipo,
                onChanged: (val) {
                  setState(() => _tipo = val);
                  _emit();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        if (_tipo == 'Preventivo') ...[
          ..._preventivos.keys.map((key) => CheckboxListTile(
                title: Text(key),
                value: _preventivos[key],
                onChanged: (val) {
                  setState(() => _preventivos[key] = val ?? false);
                  _emit();
                },
                controlAffinity: ListTileControlAffinity.leading,
              )),
        ] else ...[
          TextFormField(
            controller: _correctivoController,
            decoration: AppTheme.inputDecoration.copyWith(
              labelText: 'CORRECTIVO: Describir el mantenimiento correctivo realizado...',
            ),
            maxLines: 3,
            onChanged: (_) => _emit(),
          ),
        ]
      ],
    );
  }
}
