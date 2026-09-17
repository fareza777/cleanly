import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/monetization/rewarded_ad_manager.dart';
import '../../state/ads_provider.dart';

/// Menampilkan penawaran rewarded untuk membuka tema atau preset tambahan.
///
/// Mengembalikan `true` hanya bila pengguna benar-benar memperoleh hadiah dari
/// callback SDK — menutup iklan lebih awal tidak membuka apa pun.
Future<bool> showRewardedUnlockSheet(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
  required String purpose,
  required VoidCallback onEarned,
}) async {
  final earned = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RewardedUnlockSheet(
      title: title,
      body: body,
      purpose: purpose,
      onEarned: onEarned,
      parentRef: ref,
    ),
  );
  return earned ?? false;
}

class _RewardedUnlockSheet extends ConsumerStatefulWidget {
  const _RewardedUnlockSheet({
    required this.title,
    required this.body,
    required this.purpose,
    required this.onEarned,
    required this.parentRef,
  });

  final String title;
  final String body;
  final String purpose;
  final VoidCallback onEarned;
  final WidgetRef parentRef;

  @override
  ConsumerState<_RewardedUnlockSheet> createState() =>
      _RewardedUnlockSheetState();
}

class _RewardedUnlockSheetState extends ConsumerState<_RewardedUnlockSheet> {
  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final ads = ref.watch(adsProvider);
    final busy = ads.isRewardedBusy;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        8,
        22,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.card_giftcard_outlined,
                  color: colors.accentDeep,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
          const SizedBox(height: 16),
          for (final line in const [
            'One short ad, unlocked for good',
            'No account and no payment',
            'You can keep using everything else offline',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 17,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (ads.rewardedMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              ads.rewardedMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : _watch,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_outline, size: 20),
              label: Text(busy ? 'Loading…' : 'Watch a short ad'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _watch() async {
    final result = await ref
        .read(adsProvider.notifier)
        .showRewardedUnlock(
          canPresent: () => mounted,
          onEarned: widget.onEarned,
          purpose: widget.purpose,
        );
    if (!mounted) return;
    if (result == RewardedAdResult.earned) {
      Navigator.of(context).pop(true);
    }
  }
}
