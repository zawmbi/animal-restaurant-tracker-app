import 'package:flutter/material.dart';

class RewardIcon extends StatelessWidget {
  final String rewardText;
  final double size;

  const RewardIcon({
    super.key,
    required this.rewardText,
    this.size = 18,
  });

  //  CHANGE THESE PATHS to match your real png locations in /assets
  static const String diamondPng = 'assets/images/diamond.png';
  static const String codPng = 'assets/images/cod.png';
  static const String platesPng = 'assets/images/plate.png';
  static const String certificatePng = 'assets/images/certificate_one.png';
  static const String mementoPng = 'assets/images/memento.png';

  String? _assetFor(String t) {
    final s = t.toLowerCase();

    if (s.contains('diamond')) return diamondPng;
    if (s.contains('cod')) return codPng;
    if (s.contains('plate')) return platesPng;
    if (s.contains('certificate')) return certificatePng;
    if (s.contains('memento') || s.contains('spatula') || s.contains('dish') || s.contains('barrette') || s.contains('recipes')) {
      // treat “item rewards” as memento-style icon unless you want separate icons
      return mementoPng;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assetFor(rewardText);

    if (asset == null) {
      // no icon match → keep spacing consistent
      return SizedBox(width: size, height: size);
    }

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
