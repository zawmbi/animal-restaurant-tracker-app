import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A reference to another entity, rendered as a tappable pill.
///
/// The whole chip opens that entity's page; only the checkbox, when shown,
/// toggles it.
///
/// [checked] is shown whether or not there is a checkbox. A customer's page
/// lists the recipes they need, and those recipes are ticked off somewhere
/// else entirely — so the chip has to say whether you already have it,
/// otherwise the same fact has to be looked up on another screen.
///
/// Three signals, because one is not enough: a green border, a tick, and a
/// 10% green tint. The tint is deliberately that light — at 14% the brown
/// label drops to 4.47:1 on a card, under the 4.5:1 body text needs. The
/// border carries the weight instead, since a border costs the label no
/// contrast at all.
class EntityChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap; // open profile/details
  final bool checked; // current unlocked state
  final bool showCheckbox; // show checkbox?
  final ValueChanged<bool>? onCheckChanged;

  /// Optional chip fill override (keeps same layout/look, only color changes).
  final Color? fillColor;

  /// Cap the label at this many lines, shrinking the text to fit rather than
  /// truncating it. Null — the default — lets the chip grow to its content,
  /// which is right in a Wrap and wrong in a fixed-height grid cell.
  final int? maxLines;

  const EntityChip({
    super.key,
    required this.label,
    this.onTap,
    this.checked = false,
    this.showCheckbox = false,
    this.onCheckChanged,
    this.fillColor,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(20);
    final accent = theme.colorScheme.primary;

    final baseFill = fillColor ?? theme.colorScheme.surface;
    final fill =
        checked ? Color.alphaBlend(accent.withValues(alpha: 0.10), baseFill) : baseFill;

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
            color: fill,
            borderRadius: radius,
            border: Border.all(
              color: checked ? accent : Colors.transparent,
              width: checked ? 2 : 0,
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
                )
              else if (checked)
                // Without a checkbox there is nothing else saying so.
                Icon(Icons.check_rounded, size: 16, color: accent),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: showCheckbox || checked ? 4 : 2, right: 2),
                  child: maxLines == null
                      ? Text(
                          label,
                          overflow: TextOverflow.clip,
                          maxLines: null,
                        )
                      : AutoSizeText(
                          label,
                          maxLines: maxLines,
                          minFontSize: 10,
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
