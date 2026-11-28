import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/motion.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/expandable_section.dart';

/// Short answers to what people ask most, each opening in place.
Future<void> showHelpSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => const _HelpSheet(),
);

typedef _Answer = ({String question, String answer});

const List<_Answer> _answers = [
  (
    question: 'How do I add an expense quickly?',
    answer:
        'Tap the black + button at the bottom. To repeat one, open it in '
        'Activity and tap Spend again; the form opens filled in.',
  ),
  (
    question: 'Can it read my MoMo and bank messages?',
    answer:
        'Yes. On Add, tap "Fill from a message" and paste the SMS. With '
        'notification access on (Profile, Payment messages), payments '
        'that arrive as notifications wait for you to review and add.',
  ),
  (
    question: 'What is "safe to spend"?',
    answer:
        'What is left in your wallets, shared over the days until your '
        'next payday. Set your payday in Preferences.',
  ),
  (
    question: 'How do budgets work?',
    answer:
        'Each budget is a limit for one category from payday to payday. '
        'The line on each bar marks where spending would be at an even '
        'pace today. Not budgeted yet suggests limits from what you '
        'usually spend.',
  ),
  (
    question: 'Is my data saved if I lose my phone?',
    answer:
        'Everything is saved on your phone first, so the app works '
        'offline, and copied to your account when you are online. Sign in '
        'on a new phone to get it back. Profile shows when it last synced.',
  ),
  (
    question: 'How do I keep my money private?',
    answer:
        'In Preferences you can hide amounts on Home, hide the app in '
        'recent apps, and lock it with your fingerprint or PIN.',
  ),
];

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          Dimens.screenPadding,
          0,
          Dimens.screenPadding,
          Dimens.screenPadding,
        ),
        children: [
          Text('Help', style: context.text.sectionTitle),
          const SizedBox(height: Dimens.gapXs),
          Text(
            'Quick answers about tracking your spending.',
            style: context.text.label,
          ),
          const SizedBox(height: Dimens.gapL),
          for (final a in _answers) _AnswerTile(answer: a),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatefulWidget {
  const _AnswerTile({required this.answer});

  final _Answer answer;

  @override
  State<_AnswerTile> createState() => _AnswerTileState();
}

class _AnswerTileState extends State<_AnswerTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.gapS),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusTile),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimens.radiusTile),
          onTap: () => setState(() => _open = !_open),
          child: Semantics(
            expanded: _open,
            child: Padding(
              padding: const EdgeInsets.all(Dimens.gapL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.answer.question,
                          style: context.text.listTitle,
                        ),
                      ),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: AppMotion.expand,
                        curve: AppMotion.expandCurve,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ExpandableSection(
                    expanded: _open,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Dimens.gapS),
                      child: Text(
                        widget.answer.answer,
                        style: context.text.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
