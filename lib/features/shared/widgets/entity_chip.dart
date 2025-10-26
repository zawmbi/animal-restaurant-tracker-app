import 'package:flutter/material.dart';

/// Whole bordered chip opens details (onTap).
/// Only the checkbox toggles unlocked (onCheckChanged).
class EntityChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;              // open profile/details
  final bool checked;                     // current unlocked state
  final bool showCheckbox;                // show checkbox?
  final ValueChanged<bool>? onCheckChanged;

  const EntityChip({
    super.key,
    required this.label,
    this.onTap,
    this.checked = false,
    this.showCheckbox = false,
    this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Make the WHOLE bordered chip clickable for details:
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) {
            return theme.colorScheme.primary.withOpacity(0.06);
          }
          return null;
        }),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: radius,
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheckbox)
                // Checkbox ONLY toggles state; it won’t navigate.
                Checkbox(
                  value: checked,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => onCheckChanged?.call(v ?? false),
                ),
              Flexible(
                child: Padding(
                  // Small gap between checkbox and label (or left edge)
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
