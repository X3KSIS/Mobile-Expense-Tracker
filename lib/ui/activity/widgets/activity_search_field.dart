import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';

/// Search box for the Activity list, with a clear button.
class ActivitySearchField extends StatefulWidget {
  const ActivitySearchField({
    super.key,
    required this.initialQuery,
    required this.onChanged,
  });

  final String initialQuery;
  final ValueChanged<String> onChanged;

  @override
  State<ActivitySearchField> createState() => _ActivitySearchFieldState();
}

class _ActivitySearchFieldState extends State<ActivitySearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      style: AppTypography.body,
      decoration: InputDecoration(
        hintText: 'Search transactions',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: Dimens.iconSize,
          color: AppColors.textSecondary,
        ),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _clear,
                icon: const Icon(
                  Icons.close_rounded,
                  size: Dimens.iconSizeSmall + 2,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}
