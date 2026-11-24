import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimens.dart';

/// Temporary screen for features that are not built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.showBackButton = false,
  });

  final String title;
  final IconData icon;

  /// True for pushed routes (e.g. /add), which get an app bar with "back".
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: showBackButton ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!showBackButton) ...[
                const SizedBox(height: Dimens.gapL),
                Text(title, style: textTheme.headlineSmall),
              ],
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(
                            Dimens.radiusTile,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: AppColors.accentText,
                        ),
                      ),
                      const SizedBox(height: Dimens.gapL),
                      Text(
                        '$title is coming soon',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: Dimens.gapXs),
                      Text(
                        'This screen will be built in a later phase.',
                        style: textTheme.bodySmall,
                      ),
                    ],
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
