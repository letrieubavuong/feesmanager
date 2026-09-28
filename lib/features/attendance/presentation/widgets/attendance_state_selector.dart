import 'package:flutter/material.dart';
import '../../../../app/design_system/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/attendance_state.dart';
import 'attendance_visual_spec.dart';

class AttendanceStateSelector extends StatelessWidget {
  final AttendanceState selected;
  final List<AttendanceState> allowedStates;
  final ValueChanged<AttendanceState> onChanged;

  const AttendanceStateSelector({
    super.key,
    required this.selected,
    required this.allowedStates,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: allowedStates.map((state) {
        final spec = AttendanceVisualSpec.forState(state, l10n);
        final isSelected = selected == state;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Semantics(
              label: spec.label,
              selected: isSelected,
              button: true,
              child: Tooltip(
                message: spec.label,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged(state),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? spec.color.withValues(alpha: 0.25)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? spec.color : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Icon(
                        spec.icon,
                        size: 20,
                        color: isSelected
                            ? spec.color
                            : spec.color.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
