import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/ui/core/ui/app_shell.dart';
import 'package:flutter_expensetracker/ui/core/ui/floating_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget bar(int index, ValueChanged<int> onSelected) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: FloatingNavBar(
            destinations: AppShell.destinations,
            currentIndex: index,
            onDestinationSelected: onSelected,
            onAddPressed: () {},
          ),
        ),
      ),
    ),
  );

  for (final width in [360.0, 390.0]) {
    testWidgets('never overflows mid-transition at ${width}dp', (tester) async {
      tester.view.physicalSize = Size(width * 3, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      var index = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              bar(index, (i) => setState(() => index = i)),
        ),
      );

      for (final target in [2, 1, 3, 0]) {
        await tester.tap(
          find.bySemanticsLabel(AppShell.destinations[target].label),
        );
        // Step through the animation frame by frame.
        for (var f = 0; f < 30; f++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.takeException(), isNull);
        }
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(FloatingNavBar),
            matching: find.text(AppShell.destinations[target].label),
          ),
          findsOneWidget,
        );
      }
    });
  }
}
