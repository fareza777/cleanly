import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/cleaning_session.dart';
import '../../domain/catalog/cleaning_catalog.dart';
import '../../state/cleaning_providers.dart';

/// Riwayat sesi: progres minggu berjalan, angka jangka panjang, dan daftar
/// sesi terakhir beserta langkah yang dicentang.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.cleanly;
    final stats =
        ref.watch(statsProvider).valueOrNull ?? const CleaningStats.empty();
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final sessions = sessionsAsync.valueOrNull ?? const <CleaningSession>[];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'History',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              if (sessions.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'History options',
                  icon: Icon(Icons.more_horiz_rounded, color: colors.inkSoft),
                  onSelected: (_) => _confirmClear(context, ref),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'clear',
                      child: Text('Clear all history'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Every finished session is counted, even the short ones.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
          const SizedBox(height: 22),
          _StatsGrid(stats: stats),
          const SizedBox(height: 16),
          _WeeklyChart(stats: stats),
          if (stats.hasHistory) ...[
            const SizedBox(height: 16),
            _RoomBreakdown(stats: stats),
          ],
          const SizedBox(height: 22),
          const SectionHeader(title: 'Recent sessions'),
          if (sessionsAsync.isLoading && sessions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (sessions.isEmpty)
            const _EmptyHistory()
          else
            for (final session in sessions) ...[
              _SessionCard(
                session: session,
                onTap: () => _showDetail(context, session),
                onDelete: () => _delete(context, ref, session),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CleaningSession session,
  ) async {
    // Dikonfirmasi dulu: satu ketukan tidak boleh menghapus menit yang sudah
    // dikerjakan tanpa jalan kembali.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this session?'),
        content: Text(
          '${session.roomSpec.label} · ${session.spentMinutes} min · '
          '${formatSessionDate(session.startedAt)}. Your streak and totals are '
          'recalculated without it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(cleaningRepositoryProvider).deleteSession(session.id);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(statsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session removed from history.')),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'Every saved session and the progress built from it will be removed. '
          'Your routines and schedules stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(cleaningRepositoryProvider).clearHistory();
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(statsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('History cleared.')));
  }

  Future<void> _showDetail(BuildContext context, CleaningSession session) {
    final colors = context.cleanly;
    final family = colors.accentFor(session.roomSpec.accent);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          children: [
            OverlineLabel(formatSessionDate(session.startedAt)),
            const SizedBox(height: 8),
            Text(
              '${session.roomSpec.label} · ${session.spentMinutes} min',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${session.completedTasks} of ${session.totalTasks} steps ticked'
              '${session.routineName == null ? '' : ' · ${session.routineName}'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
            ),
            const SizedBox(height: 18),
            if (session.tasks.isEmpty)
              Text(
                'Detailed steps were not recorded for this session.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
              )
            else
              for (final task in session.tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        task.done
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 19,
                        color: task.done ? family.base : colors.inkFaint,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: task.done
                                    ? colors.ink
                                    : colors.inkFaint,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final CleaningStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                label: 'Current streak',
                value: '${stats.currentStreak}',
                unit: stats.currentStreak == 1 ? 'day' : 'days',
                highlight: stats.currentStreak > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_outlined,
                label: 'Best streak',
                value: '${stats.longestStreak}',
                unit: stats.longestStreak == 1 ? 'day' : 'days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.cleaning_services_outlined,
                label: 'Sessions',
                value: '${stats.totalSessions}',
                unit: 'total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.schedule_outlined,
                label: 'Minutes',
                value: '${stats.totalMinutes}',
                unit: 'total',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      color: highlight ? colors.primarySoft : null,
      borderColor: highlight ? colors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: highlight ? colors.primaryDeep : colors.inkFaint,
          ),
          const SizedBox(height: 12),
          // Ruang kartu menyusut di layar 320 dp, jadi angka dan satuannya
          // sama-sama boleh memendek alih-alih meluap.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.numeric(
                    size: 25,
                    color: highlight ? colors.primaryDeep : colors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.inkFaint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.stats});

  final CleaningStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final todayIndex = DateTime.now().weekday - 1;
    final best = stats.weekBest;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'This week',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${stats.weekMinutes} min total',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: _WeekBar(
                      index: index,
                      minutes: stats.weekMinutesByDay[index],
                      best: best,
                      isToday: index == todayIndex,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.index,
    required this.minutes,
    required this.best,
    required this.isToday,
  });

  /// 0 = Senin sampai 6 = Minggu.
  final int index;
  final int minutes;
  final int best;
  final bool isToday;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final ratio = best == 0 ? 0.0 : minutes / best;
    // Batang minimum tetap terlihat supaya hari kosong tidak hilang.
    final height = minutes == 0 ? 6.0 : 18 + ratio * 52;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (minutes > 0)
            Text(
              '$minutes',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.inkSoft,
                letterSpacing: 0,
              ),
            ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: height,
            decoration: BoxDecoration(
              color: minutes == 0
                  ? colors.surfaceMuted
                  : (isToday
                        ? colors.primary
                        : colors.primary.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: colors.ink, width: 1.4)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _labels[index],
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isToday ? colors.ink : colors.inkFaint,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Di mana menit pembersihan sebenarnya habis. Membantu pengguna melihat
/// area yang paling sering mereka kerjakan — dan yang paling sering terlewat.
class _RoomBreakdown extends StatelessWidget {
  const _RoomBreakdown({required this.stats});

  final CleaningStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final entries = stats.minutesByRoom.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();
    final best = entries.first.value;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Where your minutes go',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                'all time',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final entry in entries)
            _RoomRow(
              room: entry.key,
              minutes: entry.value,
              sessions: stats.sessionsByRoom[entry.key] ?? 0,
              ratio: entry.value / best,
            ),
        ],
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({
    required this.room,
    required this.minutes,
    required this.sessions,
    required this.ratio,
  });

  final CleaningRoom room;
  final int minutes;
  final int sessions;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final spec = CleaningCatalog.specFor(room);
    final family = colors.accentFor(spec.accent);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: family.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(spec.icon, size: 18, color: family.deep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spec.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '$minutes min · $sessions session'
                      '${sessions == 1 ? '' : 's'}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                FlatProgressBar(
                  progress: ratio,
                  height: 6,
                  color: family.base,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final CleaningSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final family = colors.accentFor(session.roomSpec.accent);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: family.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(session.roomSpec.icon, color: family.deep, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.roomSpec.label} · ${session.spentMinutes} min',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatSessionDate(session.startedAt)} · '
                  '${session.completedTasks}/${session.totalTasks} steps'
                  '${session.routineName == null ? '' : ' · ${session.routineName}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ],
            ),
          ),
          if (session.finishedEverything)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.verified_rounded, color: family.base, size: 19),
            ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Remove from history',
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: colors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, color: colors.primary, size: 26),
          const SizedBox(height: 12),
          Text('Nothing here yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Finish your first session and it will appear here with the minutes '
            'you cleaned and the steps you ticked off.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
        ],
      ),
    );
  }
}

const _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _weekdayShort = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Tanggal yang ramah dibaca: "Today", "Yesterday", lalu "12 Sep".
String formatSessionDate(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final difference = today.difference(day).inDays;
  final clock =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  if (difference == 0) return 'Today · $clock';
  if (difference == 1) return 'Yesterday · $clock';
  if (difference < 7) {
    return '${_weekdayShort[local.weekday - 1]} · $clock';
  }
  return '${local.day} ${_monthShort[local.month - 1]} · $clock';
}
