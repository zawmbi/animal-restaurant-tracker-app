import 'package:flutter/material.dart';

/// Whole bordered chip opens details (onTap).
/// Only the checkbox toggles unlocked (onCheckChanged).
class EntityChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap; // open profile/details
  final bool checked; // current unlocked state
  final bool showCheckbox; // show checkbox?
  final ValueChanged<bool>? onCheckChanged;

  /// Optional chip fill override (keeps same layout/look, only color changes).
  final Color? fillColor;

  const EntityChip({
    super.key,
    required this.label,
    this.onTap,
    this.checked = false,
    this.showCheckbox = false,
    this.onCheckChanged,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            // ignore: deprecated_member_use
            return theme.colorScheme.primary.withOpacity(0.06);
          }
          return null;
        }),
        child: Ink(
          decoration: BoxDecoration(
            color: fillColor ?? theme.colorScheme.surface,
            borderRadius: radius,
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheckbox)
                Checkbox(
                  value: checked,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => onCheckChanged?.call(v ?? false),
                ),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(left: showCheckbox ? 4 : 2, right: 2),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
