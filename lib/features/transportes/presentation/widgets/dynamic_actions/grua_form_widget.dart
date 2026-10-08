import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class GruaFormWidget extends StatefulWidget {
  final void Function(AccionGruaRequest) onChanged;

  const GruaFormWidget({super.key, required this.onChanged});

  @override
  State<GruaFormWidget> createState() => _GruaFormWidgetState();
}

class _GruaFormWidgetState extends State<GruaFormWidget> {
  final _actividadController = TextEditingController();
  final _horometroInicialController = TextEditingController();
  final _horometroFinalController = TextEditingController();

  void _emit() {
    widget.onChanged(AccionGruaRequest(
      actividad: _actividadController.text,
      horometroInicial: double.tryParse(_horometroInicialController.text),
      horometroFinal: double.tryParse(_horometroFinalController.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _actividadController,
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: 'ACTIVIDAD A REALIZAR',
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        TextFormField(
          controller: _horometroInicialController,
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: 'HORÓMETRO INICIAL',
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        TextFormField(
          controller: _horometroFinalController,
          decoration: AppTheme.inputDecoration.copyWith(
            labelText: 'HORÓMETRO FINAL',
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
