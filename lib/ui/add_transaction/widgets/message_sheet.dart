import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/money_message.dart';
import '../../../utils/currency.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/status_badge.dart';

/// Opens the sheet for pasting a mobile money or bank SMS. Resolves to the
/// message read from it, or null when dismissed.
Future<MoneyMessage?> showMessageSheet(
  BuildContext context, {
  required MoneyMessage? Function(String text) read,
  required VoidCallback onOpenWallets,
}) {
  return showModalBottomSheet<MoneyMessage>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => MessageSheet(read: read, onOpenWallets: onOpenWallets),
  );
}

/// A box to paste an SMS into, a live preview of what was understood, and
/// a button to fill the form with it. Cash withdrawals point to Wallets
/// instead, since they move money rather than spend it.
class MessageSheet extends StatefulWidget {
  const MessageSheet({
    super.key,
    required this.read,
    required this.onOpenWallets,
  });

  final MoneyMessage? Function(String text) read;
  final VoidCallback onOpenWallets;

  @override
  State<MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<MessageSheet> {
  final _text = TextEditingController();
  MoneyMessage? _message;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String text) => setState(() => _message = widget.read(text));

  /// Reads the clipboard only when asked, so no "pasted" notice appears
  /// unexpectedly.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (!mounted || text.isEmpty) return;
    _text.text = text;
    _onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    final withdrawal = message?.kind == MoneyMessageKind.withdrawal;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Dimens.screenPadding,
            0,
            Dimens.screenPadding,
            Dimens.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Fill from a message', style: context.text.sectionTitle),
              const SizedBox(height: Dimens.gapXs),
              Text(
                'Paste an MTN MoMo, Airtel Money, Zamtel Kwacha or bank SMS.',
                style: context.text.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: Dimens.gapL),
              TextField(
                controller: _text,
                onChanged: _onChanged,
                minLines: 4,
                maxLines: 8,
                style: context.text.body,
                decoration: InputDecoration(
                  hintText: 'You have paid ZMW 150.00 to …',
                  suffixIcon: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Paste',
                      onPressed: _paste,
                      icon: const Icon(Icons.content_paste_rounded),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimens.gapL),
              FadeSwitcher(
                child: message == null
                    ? _Hint(
                        key: ValueKey(_text.text.isEmpty),
                        empty: _text.text.trim().isEmpty,
                      )
                    : _Preview(
                        key: const ValueKey('preview'),
                        message: message,
                      ),
              ),
              const SizedBox(height: Dimens.sectionGap),
              PrimaryButton(
                label: withdrawal ? 'Open Wallets' : 'Fill in the form',
                onPressed: message == null
                    ? null
                    : withdrawal
                    ? () {
                        Navigator.of(context).pop();
                        widget.onOpenWallets();
                      }
                    : () => Navigator.of(context).pop(message),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({super.key, required this.empty});

  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Text(
      empty
          ? 'The amount, who it was with, the date and any charge are filled '
                'in for you to check.'
          : "Couldn't find an amount and whether money came in or went out.",
      style: context.text.caption,
    );
  }
}

/// What was understood: direction, amount, who, provider and charge.
class _Preview extends StatelessWidget {
  const _Preview({super.key, required this.message});

  final MoneyMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (tone, label) = switch (message.kind) {
      MoneyMessageKind.received => (StatusTone.success, 'Money in'),
      MoneyMessageKind.spent => (StatusTone.neutral, 'Money out'),
      MoneyMessageKind.withdrawal => (StatusTone.warning, 'Cash withdrawal'),
    };
    final fee = message.fee;
    final details = [
      ?message.counterparty,
      ?message.provider,
      if (fee != null) 'Charge ${formatZmw(fee)}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(Dimens.gapL),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(Dimens.radiusTile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatZmw(message.amount),
                  style: context.text.statValue,
                ),
              ),
              StatusBadge(tone: tone, label: label),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: Dimens.gapXs),
            Text(details, style: context.text.caption),
          ],
          if (message.kind == MoneyMessageKind.withdrawal) ...[
            const SizedBox(height: Dimens.gapS),
            Text(
              'Withdrawing cash moves money between your wallets, so it '
              "isn't spending. Record it with Move money in Wallets.",
              style: context.text.caption.copyWith(color: colors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}
