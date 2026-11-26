import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/ui/core/themes/motion.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/ui/core/ui/expandable_section.dart';
import 'package:flutter_expensetracker/ui/core/ui/pressable.dart';
import 'package:flutter_expensetracker/ui/core/ui/slow_refresh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  group('SlowRefresh', () {
    testWidgets('refreshes after a long pull, then settles back', (
      tester,
    ) async {
      var refreshes = 0;
      await tester.pumpWidget(
        app(
          SlowRefresh(
            onRefresh: () async => refreshes++,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 2000)],
            ),
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pump();
      expect(refreshes, 1);
      expect(find.bySemanticsLabel('Refreshing'), findsOneWidget);

      // Held for the minimum time, then glides away.
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Refreshing'), findsNothing);
    });

    testWidgets('a short pull does not refresh', (tester) async {
      var refreshes = 0;
      await tester.pumpWidget(
        app(
          SlowRefresh(
            onRefresh: () async => refreshes++,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 2000)],
            ),
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(refreshes, 0);
    });
  });

  testWidgets('Pressable shrinks to 95% and springs back', (tester) async {
    await tester.pumpWidget(
      app(
        Center(
          child: Pressable(
            child: GestureDetector(
              onTap: () {},
              child: const ColoredBox(
                color: Colors.black,
                child: SizedBox(width: 100, height: 50),
              ),
            ),
          ),
        ),
      ),
    );
    double scale() => tester
        .widget<ScaleTransition>(
          find.descendant(
            of: find.byType(Pressable),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Pressable)),
    );
    await tester.pump();
    await tester.pump(AppMotion.pressDown);
    expect(scale(), closeTo(AppMotion.pressScale, 0.001));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1, 0.001));
  });

  testWidgets('ExpandableSection eases open over 350 ms', (tester) async {
    Widget section(bool expanded) => app(
      Column(
        children: [
          ExpandableSection(
            expanded: expanded,
            child: const SizedBox(height: 100, child: Text('Details')),
          ),
        ],
      ),
    );

    await tester.pumpWidget(section(false));
    expect(find.text('Details'), findsNothing);

    await tester.pumpWidget(section(true));
    await tester.pump(const Duration(milliseconds: 175));
    final mid = tester.getSize(find.byType(ExpandableSection)).height;
    expect(mid, greaterThan(50)); // Ease out: past halfway at half time.
    expect(mid, lessThan(100));

    await tester.pump(const Duration(milliseconds: 175));
    expect(tester.getSize(find.byType(ExpandableSection)).height, 100);
  });
}
