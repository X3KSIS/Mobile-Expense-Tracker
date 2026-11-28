import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/app_logo.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/form_error_banner.dart';
import '../../core/ui/primary_button.dart';
import '../view_models/app_lock_view_model.dart';

/// Covers the app until the owner unlocks it with the phone's fingerprint,
/// face or screen lock.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.viewModel});

  final AppLockViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.screenPadding),
          child: ListenableBuilder(
            listenable: Listenable.merge([viewModel, viewModel.unlock]),
            builder: (context, _) => Column(
              children: [
                const Spacer(),
                const AppLogo(size: Dimens.authLogoSize),
                const SizedBox(height: Dimens.sectionGap),
                Text(
                  'Expense Tracker is locked',
                  style: context.text.screenTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimens.gapS),
                Text(
                  'Use your fingerprint, face or phone PIN to open it',
                  style: context.text.label,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FadeSwitcher(child: _message()),
                PrimaryButton(
                  label: 'Unlock',
                  loading: viewModel.unlock.running,
                  onPressed: viewModel.unlock.execute,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _message() {
    final message = viewModel.message;
    if (message == null) return const SizedBox.shrink(key: ValueKey('none'));
    return Padding(
      key: ValueKey(message),
      padding: const EdgeInsets.only(bottom: Dimens.gapL),
      child: FormErrorBanner(message: message),
    );
  }
}
