import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';

/// Widget que imita un medidor de combustible con 5 niveles.
/// Devuelve el valor entero [0, 25, 50, 75, 100].
class FuelGaugeSelector extends StatelessWidget {
  const FuelGaugeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final void Function(int) onChanged;

  static const _labels = ['E', '1/4', '1/2', '3/4', 'F'];
  static const _values = [0, 25, 50, 75, 100];

  Color _colorForValue(int v) {
    if (v <= 25) return AppTheme.error;
    if (v <= 50) return Colors.orange;
    if (v <= 75) return Colors.yellow.shade700;
    return AppTheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nivel de Combustible',
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.border),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_gas_station,
                        color: value == null
                            ? AppTheme.textDisabled
                            : _colorForValue(value!),
                        size: 32),
                    const Spacer(),
                    Text(
                      value == null ? 'Seleccione' : '$value%',
                      style: AppTheme.bodySmall.copyWith(
                        color: value == null
                            ? AppTheme.textSecondary
                            : _colorForValue(value!),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_values.length, (i) {
                    final isSelected = _values[i] == value;
                    final segColor = _colorForValue(_values[i]);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: i == _values.length - 1 ? 0 : 4),
                        child: Semantics(
                          button: true,
                          label: '${_values[i]}% de combustible',
                          selected: isSelected,
                          child: InkWell(
                            onTap: () => onChanged(_values[i]),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? segColor
                                    : segColor.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      isSelected ? segColor : AppTheme.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _labels[i],
                                    style: AppTheme.bodySmall.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
