import 'package:flutter/material.dart';

import '../../core/themes/motion.dart';
import '../view_models/app_lock_view_model.dart';
import 'lock_screen.dart';

/// Puts the [LockScreen] over [child] while the app is locked, and tells
/// the lock when the app leaves and returns to the screen.
///
/// The lock appears at once, so nothing behind it shows, and fades away
/// on unlock. The prompt opens by itself each time the app locks; after
/// that, the Unlock button asks again.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.viewModel, required this.child});

  final AppLockViewModel viewModel;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late bool _wasLocked = widget.viewModel.isLocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.viewModel.addListener(_onChanged);
    if (_wasLocked) _promptAfterFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        widget.viewModel.appHidden();
      case AppLifecycleState.resumed:
        widget.viewModel.appResumed();
      case _:
        break;
    }
  }

  void _onChanged() {
    final locked = widget.viewModel.isLocked;
    if (locked && !_wasLocked) _promptAfterFrame();
    _wasLocked = locked;
  }

  /// Once the lock is on screen, so the prompt opens over it.
  void _promptAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.viewModel.isLocked) {
        widget.viewModel.unlock.execute();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.viewModel.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final locked = widget.viewModel.isLocked;
        final reduceMotion =
            MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        return Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              excluding: locked,
              child: TickerMode(enabled: !locked, child: widget.child),
            ),
            IgnorePointer(
              ignoring: !locked,
              child: AnimatedOpacity(
                opacity: locked ? 1 : 0,
                duration: locked || reduceMotion
                    ? Duration.zero
                    : AppMotion.medium,
                curve: AppMotion.move,
                child: ExcludeSemantics(
                  excluding: !locked,
                  child: LockScreen(viewModel: widget.viewModel),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
