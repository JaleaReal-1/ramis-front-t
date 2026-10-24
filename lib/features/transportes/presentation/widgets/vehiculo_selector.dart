import 'package:flutter/material.dart';
import 'observacion_fields.dart';

class VehiculoSelector extends StatelessWidget {
  const VehiculoSelector(
      {super.key,
      required this.vehiculos,
      required this.onChanged,
      this.value,
      this.vehiculoActivoId});
  final List<Map<String, dynamic>> vehiculos;
  final int? value;
  final int? vehiculoActivoId;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    final visibles = vehiculos
        .where((v) =>
            v['estado'] == 'disponible' ||
            v['estado'] == 'en_ruta' ||
            v['id'] == vehiculoActivoId ||
            (v['estado_semaforo'] == 'rojo' && v['estado'] != 'inactivo'))
        .toList();
    final seleccionados = visibles.where((v) => v['id'] == value);
    final seleccionado = seleccionados.isEmpty ? null : seleccionados.first;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField<int>(
        key: ValueKey(
            '$value-${visibles.map((v) => "${v['id']}:${v['estado_semaforo']}").join(',')}'),
        initialValue: seleccionado == null ? null : value,
        isExpanded: true,
        decoration: const InputDecoration(
            labelText: 'Vehículo',
            prefixIcon: Icon(Icons.local_shipping_outlined)),
        items: visibles.map((v) {
          final rojo = v['estado_semaforo'] == 'rojo';
          return DropdownMenuItem<int>(
              value: v['id'] as int,
              enabled: !rojo,
              child: Row(children: [
                Icon(Icons.circle,
                    size: 14,
                    color: colorSemaforo(
                        v['estado_semaforo'] as String? ?? 'verde')),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        rojo
                            ? "${v['placa']} · No disponible por falla crítica"
                            : "${v['placa']} - ${v['marca']} ${v['modelo']}${v['estado'] == 'en_ruta' ? ' · Relevo disponible' : ''}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis)),
              ]));
        }).toList(),
        onChanged: (id) {
          if (id != null) onChanged(visibles.firstWhere((v) => v['id'] == id));
        },
        validator: (id) => id == null || seleccionado == null
            ? 'Seleccione un vehículo'
            : seleccionado['estado_semaforo'] == 'rojo'
                ? 'No disponible por falla crítica'
                : null,
      ),
      if (seleccionado?['estado_semaforo'] == 'amarillo')
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
                '⚠ Advertencia preventiva: ${seleccionado?['observaciones_pendientes'] ?? 'El vehículo tiene observaciones leves pendientes de revisión.'}',
                style: const TextStyle(color: Colors.orange))),
    ]);
  }
}
