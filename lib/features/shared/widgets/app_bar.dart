import 'package:flutter/material.dart';

class ARAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? section; // optional: "Customers", "Letters", etc.
  final List<Widget>? actions;

  const ARAppBar({
    super.key,
    required this.title,
    this.section,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Home',
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            )
          : null,
      title: _BreadcrumbTitle(
        title: title,
        section: section,
        showHome: canPop, // if already on home, don't show "Home >"
        onHomeTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
      actions: actions,
    );
  }
}

class _BreadcrumbTitle extends StatelessWidget {
  final String title;
  final String? section;
  final bool showHome;
  final VoidCallback onHomeTap;

  const _BreadcrumbTitle({
    required this.title,
    this.section,
    required this.showHome,
    required this.onHomeTap,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;

    Widget crumb(String text, {VoidCallback? onTap}) {
      final child = Text(text, style: textStyle, overflow: TextOverflow.ellipsis);
      if (onTap == null) return child;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: child,
        ),
      );
    }

    Widget sep() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('›', style: textStyle),
        );

    // Horizontal scroll so long titles don’t overflow.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHome) ...[
            crumb('Home', onTap: onHomeTap),
            sep(),
          ],
          if (section != null && section!.trim().isNotEmpty) ...[
            crumb(section!),
            sep(),
          ],
          crumb(title),
        ],
      ),
    );
  }
}
