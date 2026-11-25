import 'package:flutter/material.dart';

import '../themes/dimens.dart';
import 'fade_switcher.dart';
import 'form_error_banner.dart';

/// Space for a form-level error that fades and expands in when [message]
/// appears, and collapses away when it clears.
class FormErrorSlot extends StatelessWidget {
  const FormErrorSlot({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return FadeSwitcher(
      child: text == null
          ? const SizedBox(width: double.infinity, key: ValueKey('none'))
          : Padding(
              key: ValueKey(text),
              padding: const EdgeInsets.only(bottom: Dimens.sectionGap),
              child: FormErrorBanner(message: text),
            ),
    );
  }
}
