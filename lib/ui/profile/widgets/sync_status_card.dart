import 'package:flutter/material.dart';

import '../../../data/repositories/sync/sync_repository.dart';
import '../../../utils/dates.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/fade_switcher.dart';
import '../../core/ui/status_badge.dart';

/// Whether everything is saved online, with a Sync now button.
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({
    super.key,
    required this.status,
    required this.lastSyncedAt,
    required this.now,
    required this.onSyncNow,
  });

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final DateTime now;
  final VoidCallback onSyncNow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final last = lastSyncedAt;
    final (tone, title, detail) = switch (status) {
      SyncStatus.idle => (
        StatusTone.success,
        'Saved online',
        last == null ? 'Up to date' : 'Last synced ${formatAgo(last, now)}',
      ),
      SyncStatus.syncing => (
        StatusTone.neutral,
        'Syncing…',
        'Sending and fetching changes',
      ),
      SyncStatus.failed => (
        StatusTone.warning,
        'Waiting for connection',
        'Changes are safe on this phone and go up once you are online',
      ),
      SyncStatus.off => (
        StatusTone.neutral,
        'Not syncing',
        'Sign in to save your data online',
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gapL,
        Dimens.gapM,
        Dimens.gapS,
        Dimens.gapM,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusList),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          StatusMark(tone: tone, size: 20),
          const SizedBox(width: Dimens.gapM),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: FadeSwitcher(
                child: Column(
                  key: ValueKey(status),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.listTitle),
                    const SizedBox(height: 2),
                    Text(detail, style: context.text.caption),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: status == SyncStatus.syncing || status == SyncStatus.off
                ? null
                : onSyncNow,
            child: const Text('Sync now'),
          ),
        ],
      ),
    );
  }
}
