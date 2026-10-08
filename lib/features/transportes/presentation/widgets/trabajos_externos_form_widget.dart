import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class TrabajosExternosFormWidget extends StatefulWidget {
  const TrabajosExternosFormWidget({super.key, required this.onChanged});

  final ValueChanged<AccionTrabajosExternosRequest?> onChanged;

  @override
  State<TrabajosExternosFormWidget> createState() =>
      _TrabajosExternosFormWidgetState();
}

class _TrabajosExternosFormWidgetState
    extends State<TrabajosExternosFormWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: _controller,
        decoration: AppTheme.inputDecoration.copyWith(
          labelText: 'TRABAJOS',
          helperText: 'Describir los trabajos realizados con el vehículo',
          helperMaxLines: 2,
          alignLabelWithHint: true,
        ),
        maxLines: 3,
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Describa los trabajos realizados'
            : null,
        onChanged: (value) {
          final descripcion = value.trim();
          widget.onChanged(descripcion.isEmpty
              ? null
              : AccionTrabajosExternosRequest(
                  descripcionTrabajos: descripcion,
                ));
        },
      );
}
