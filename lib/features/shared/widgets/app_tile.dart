import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../theme/app_theme.dart';

class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.label,
    this.onTap,
    this.trailing,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Container(
      decoration: BoxDecoration(
        color: kCreamDark,
        border: Border.all(color: kGreen, width: 3),
        borderRadius: radius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: AutoSizeText(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      wrapWords: true,
                      minFontSize: 10,
                      stepGranularity: 1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                Positioned(top: 4, right: 4, child: trailing!),
            ],
          ),
        ),
      ),
    );
  }
}
