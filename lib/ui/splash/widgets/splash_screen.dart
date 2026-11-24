import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/result.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/app_logo.dart';
import '../view_models/splash_view_model.dart';

/// Logo, wordmark and tagline, faded and scaled in over ~600 ms.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.viewModel});

  final SplashViewModel viewModel;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.9,
    end: 1,
  ).animate(_curve);

  @override
  void initState() {
    super.initState();
    _controller.forward();
    widget.viewModel.start.addListener(_onStartChanged);
    widget.viewModel.start.execute();
  }

  void _onStartChanged() {
    if (!mounted) return;
    final result = widget.viewModel.start.result;
    if (result case Ok<String>(:final value)) context.go(value);
  }

  @override
  void dispose() {
    widget.viewModel.start.removeListener(_onStartChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _curve,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 96),
                const SizedBox(height: Dimens.cardPadding),
                const Text('ExpenseTrack', style: AppTypography.wordmark),
                const SizedBox(height: 6),
                Text(
                  'Know where your kwacha goes',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
