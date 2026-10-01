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

  final int value;
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
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.surface,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Gauge icon
              Icon(
                Icons.local_gas_station,
                color: _colorForValue(value),
                size: 32,
              ),
              const SizedBox(width: 12),
              // Segments
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_values.length, (i) {
                    final isSelected = _values[i] == value;
                    final segColor = _colorForValue(_values[i]);
                    return GestureDetector(
                      onTap: () => onChanged(_values[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? segColor : segColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? segColor : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _labels[i],
                            style: AppTheme.bodySmall.copyWith(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Current value
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '$value%',
                  style: AppTheme.bodySmall.copyWith(
                    color: _colorForValue(value),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
