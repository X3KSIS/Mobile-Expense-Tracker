import 'package:flutter/material.dart';

/// Centres [children] vertically when they fit, and scrolls when they do
/// not (small phones, or with the keyboard open).
class CenteredScrollBody extends StatelessWidget {
  const CenteredScrollBody({
    super.key,
    required this.children,
    required this.padding,
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - padding.vertical).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
