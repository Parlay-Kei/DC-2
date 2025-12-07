import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/theme.dart';

/// Official DirectCuts logo component using SVG asset
class DCLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const DCLogo({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/dc_logo.svg',
      width: size,
      height: size,
    );
  }
}

/// Logo with background container (for splash screens, etc.)
class DCLogoWithBackground extends StatelessWidget {
  final double size;
  final double padding;
  final Color? backgroundColor;
  final double borderRadius;

  const DCLogoWithBackground({
    super.key,
    this.size = 80,
    this.padding = 16,
    this.backgroundColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + padding * 2,
      height: size + padding * 2,
      decoration: BoxDecoration(
        color: backgroundColor ?? DCTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: DCLogo(size: size),
      ),
    );
  }
}

/// Watermark version of logo (for backgrounds)
class DCLogoWatermark extends StatelessWidget {
  final double size;
  final double opacity;

  const DCLogoWatermark({
    super.key,
    this.size = 300,
    this.opacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SvgPicture.asset(
        'assets/images/dc_logo.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          DCTheme.text,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
