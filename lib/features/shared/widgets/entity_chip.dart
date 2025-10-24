import 'package:flutter/material.dart';

class EntityChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool checked;
  const EntityChip({super.key, required this.label, this.onTap, this.checked = false});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (checked) const Icon(Icons.check, size: 16),
        if (checked) const SizedBox(width: 6),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    return InkWell(
      onTap: onTap,
      child: Chip(
        label: content,
        side: const BorderSide(width: 1),
      ),
    );
  }
}
