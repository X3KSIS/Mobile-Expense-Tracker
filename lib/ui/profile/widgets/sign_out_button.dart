import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';

/// Full-width outlined "Sign out" button. Asks for confirmation first.
class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
    required this.onConfirmed,
    this.loading = false,
  });

  final VoidCallback onConfirmed;
  final bool loading;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          "You'll need to sign in again to see your transactions.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : () => _confirm(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentText,
        minimumSize: const Size.fromHeight(Dimens.primaryButtonHeight),
        shape: const StadiumBorder(),
      ),
      icon: loading
          ? const SizedBox.square(
              dimension: Dimens.iconSizeSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentText,
              ),
            )
          : const Icon(Icons.logout_rounded, size: Dimens.iconSizeSmall + 2),
      label: const Text('Sign out'),
    );
  }
}
