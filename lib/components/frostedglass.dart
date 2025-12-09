import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

import '../theme/app_colors.dart';

class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color borderColor;
  final double blurX;
  final double blurY;
  final Color tintColor;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = 24,
    this.borderColor = const Color(0xFFE5E5E5),
    this.blurX = 200,
    this.blurY = 100,
    this.tintColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: padding,
      child: Container(
        child: child,
      )
    ).asGlass(
      enabled: true,
      frosted: true,
      tintColor: tintColor,
      clipBorderRadius: BorderRadius.circular(borderRadius),
      blurX: blurX,
      blurY: blurY,
    );
  }
}
