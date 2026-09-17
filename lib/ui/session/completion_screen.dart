import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/cleaning_session.dart';
import '../../state/ads_provider.dart';
import '../../state/cleaning_providers.dart';

/// Ringkasan setelah sesi selesai: confetti, angka yang bisa dibanggakan, dan
/// satu langkah berikutnya yang jelas.
class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({super.key, required this.session});

  final CleaningSession session;

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  var _leaving = false;

  /// Interstitial hanya di sini: setelah pengguna menutup ringkasan, bukan di
  /// tengah timer. Bila iklan belum siap, layar langsung ditutup seperti biasa.
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await ref
        .read(adsProvider.notifier)
        .showCompletionInterstitial(canPresent: () => mounted);
    if (mounted) Navigator.of(context).pop();
  }

  /// Menyalin ringkasan sebagai teks biasa, tanpa paket tambahan dan tanpa
  /// jaringan: berguna untuk membagi daftar tugas ke pasangan atau keluarga.
  Future<void> _copySummary(List<SessionTask> ticked) async {
    final session = widget.session;
    final lines = <String>[
      '${AppIdentity.name} · ${session.roomSpec.label} · '
          '${session.spentMinutes} min',
      '${session.completedTasks} of ${session.totalTasks} steps ticked',
      for (final task in ticked) '• ${task.title}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied to the clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final session = widget.session;
    final accent = colors.accentFor(session.roomSpec.accent);
    final stats =
        ref.watch(statsProvider).valueOrNull ?? const CleaningStats.empty();
    final perfect = session.finishedEverything;
    final ticked = session.tasks.where((task) => task.done).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: ProgressRing(
                            progress: perfect ? 1 : session.completion,
                            size: 188,
                            strokeWidth: 12,
                            color: accent.base,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  perfect
                                      ? Icons.check_rounded
                                      : Icons.emoji_events_outlined,
                                  size: 40,
                                  color: accent.deep,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${session.spentMinutes} min',
                                  style: AppTheme.numeric(
                                    size: 28,
                                    color: colors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          perfect
                              ? '${session.roomSpec.label} looks brand new'
                              : '${session.roomSpec.label} is better than before',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          perfect
                              ? 'Every step on the list is ticked off.'
                              : 'You ticked off ${session.completedTasks} of '
                                    '${session.totalTasks} steps. That still counts.',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                label: 'Steps',
                                value:
                                    '${session.completedTasks}/${session.totalTasks}',
                                accent: accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatTile(
                                label: 'Streak',
                                value:
                                    '${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'}',
                                accent: accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatTile(
                                label: 'This week',
                                value: '${stats.weekMinutes} min',
                                accent: accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (ticked.isNotEmpty)
                          SoftCard(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const OverlineLabel('Ticked off'),
                                const SizedBox(height: 12),
                                for (final task in ticked.take(5))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 17,
                                          color: accent.base,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              color: colors.ink,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (ticked.length > 5)
                                  Text(
                                    '+${ticked.length - 5} more',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: colors.inkFaint),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            stats.cleanedToday
                                ? 'Today is already counted. Anything else is a bonus.'
                                : 'That is today on the board.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: colors.inkFaint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _leave,
                            child: const Text('Back home'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _copySummary(ticked),
                          icon: const Icon(Icons.copy_all_rounded, size: 18),
                          label: const Text('Copy this checklist'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your history is saved on this device.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.inkFaint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ConfettiBurst(
              origin: const Alignment(0, -0.35),
              pieces: perfect ? 72 : 44,
              seed: session.id.hashCode,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final AccentFamily accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.numeric(size: 19, color: accent.deep),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.inkSoft,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
