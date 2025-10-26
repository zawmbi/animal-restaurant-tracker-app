// lib/features/shared/widgets/entity_chip.dart
import 'package:flutter/material.dart';

/// Compact clickable chip with optional checkbox and a small check badge when checked.
class EntityChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool checked;
  final bool showCheckbox;
  final ValueChanged<bool?>? onCheckChanged; // <-- bool? matches Checkbox

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
    final chip = Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCheckbox)
            Checkbox(
              value: checked,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onCheckChanged, // <-- signatures now match
            ),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      side: const BorderSide(width: 1),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            chip,
            // Small check badge in the top-right when checked
            Positioned(
              top: 6,
              right: 6,
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: checked ? 1.0 : 0.0,
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
