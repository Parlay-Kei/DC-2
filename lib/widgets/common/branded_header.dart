import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'dc_logo.dart';

/// Branded header matching the web app's PageHeader component
/// Features: Red gradient background, watermark logo, personalized greeting
class BrandedHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? rightAction;
  final bool centerTitle;
  final double bottomRadius;

  const BrandedHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.rightAction,
    this.centerTitle = false,
    this.bottomRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        color: DCTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
      ),
      child: Stack(
        children: [
          // Watermark Logo
          Positioned.fill(
            child: Center(
              child: DCLogoWatermark(
                size: 180,
                opacity: 0.2,
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Back button and/or Right action
                if (showBack || rightAction != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showBack)
                          GestureDetector(
                            onTap: onBack ?? () => Navigator.of(context).pop(),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        if (rightAction != null) rightAction!,
                      ],
                    ),
                  ),

                // Title Row
                if (title != null || subtitle != null)
                  Container(
                    alignment:
                        centerTitle ? Alignment.center : Alignment.centerLeft,
                    padding: centerTitle
                        ? const EdgeInsets.symmetric(vertical: 16)
                        : EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: centerTitle
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: centerTitle ? 28 : 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign:
                                centerTitle ? TextAlign.center : TextAlign.left,
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                            ),
                            textAlign:
                                centerTitle ? TextAlign.center : TextAlign.left,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
