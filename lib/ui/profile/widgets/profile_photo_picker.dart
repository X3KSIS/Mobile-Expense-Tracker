import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/user_avatar.dart';

/// The large avatar with Choose photo and, when there is one, Remove.
class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({
    super.key,
    required this.initials,
    required this.photo,
    required this.busy,
    required this.onChoose,
    required this.onRemove,
  });

  final String initials;
  final Uint8List? photo;

  /// True while a photo is being saved.
  final bool busy;
  final VoidCallback onChoose;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: photo == null ? 'Choose a profile photo' : 'Change photo',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: busy ? null : onChoose,
            child: UserAvatar(initials: initials, photo: photo, large: true),
          ),
        ),
        const SizedBox(height: Dimens.gapS),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: busy ? null : onChoose,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(photo == null ? 'Choose photo' : 'Change photo'),
            ),
            if (photo != null)
              TextButton(
                onPressed: busy ? null : onRemove,
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textSecondary,
                ),
                child: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
