import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/cleaning_session.dart';
import '../../data/models/custom_routine.dart';
import '../../domain/catalog/cleaning_catalog.dart';
import '../../state/ads_provider.dart';
import '../../state/app_settings.dart';
import '../../state/cleaning_providers.dart';
import '../../state/session_controller.dart';
import '../monetization/rewarded_unlock_sheet.dart';
import '../routines/routines_screen.dart';
import '../session/session_screen.dart';
import 'widgets/duration_picker.dart';
import 'widgets/room_picker.dart';
import 'widgets/week_strip.dart';

/// Alur utama: pilih waktu, pilih ruangan, mulai.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.cleanly;
    final draft = ref.watch(sessionDraftProvider);
    final stats =
        ref.watch(statsProvider).valueOrNull ?? const CleaningStats.empty();
    final deepUnlocked = ref.watch(
      settingsProvider.select((settings) => settings.deepPresetUnlocked),
    );
    final homeRoutine = ref.watch(homeRoutineProvider);
    final notifier = ref.read(sessionDraftProvider.notifier);
    // Sesi yang belum ditutup (termasuk yang dipulihkan setelah aplikasi
    // ditutup paksa) tetap bisa dilanjutkan dari sini.
    final active = ref.watch(sessionControllerProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          _Greeting(stats: stats),
          const SizedBox(height: 18),
          if (active != null) ...[
            _ResumeCard(
              session: active,
              onContinue: () => _resume(context, ref),
              onDiscard: () => _discard(context, ref),
            ),
            const SizedBox(height: 16),
          ],
          _TodayCard(stats: stats),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'How long do you have?',
            subtitle: 'The checklist adapts to the time you pick.',
          ),
          DurationPicker(
            selected: draft.minutes,
            deepSelected: draft.deepPreset,
            deepUnlocked: deepUnlocked,
            onSelected: notifier.selectMinutes,
            onDeepTap: () => _toggleDeep(context, ref, draft),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'Where are you cleaning?',
            subtitle: 'One room keeps it honest. Pick the one that bothers you.',
          ),
          RoomPicker(
            selected: draft.room,
            onSelected: notifier.selectRoom,
          ),
          const SizedBox(height: 24),
          _PlanPreview(draft: draft),
          const SizedBox(height: 14),
          _StartButton(
            draft: draft,
            busy: active != null,
            onStart: () => _start(context, ref, draft),
          ),
          if (homeRoutine != null) ...[
            const SizedBox(height: 22),
            _RoutineQuickStart(
              routine: homeRoutine,
              onStart: () => _startRoutine(context, ref, homeRoutine),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 15, color: colors.inkFaint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Works offline. Your history stays on this device.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDeep(
    BuildContext context,
    WidgetRef ref,
    SessionDraft draft,
  ) async {
    final notifier = ref.read(sessionDraftProvider.notifier);
    if (draft.deepPreset) {
      notifier.clearDeepPreset();
      return;
    }
    final unlocked =
        ref.read(settingsProvider).deepPresetUnlocked;
    if (unlocked) {
      notifier.useDeepPreset(unlocked: true);
      return;
    }
    final earned = await showRewardedUnlockSheet(
      context,
      ref,
      title: 'Deep clean preset',
      body:
          'Unlock a 45-minute checklist that walks through every step for the '
          'room you picked — including the ones most people skip.',
      purpose: 'the deep clean preset',
      onEarned: () {},
    );
    if (!earned || !context.mounted) return;
    try {
      await ref.read(settingsProvider.notifier).unlockDeepPreset();
    } catch (_) {
      // Bila penyimpanan gagal, preset hanya aktif untuk sesi ini.
    }
    notifier.useDeepPreset(unlocked: true);
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    SessionDraft draft,
  ) async {
    final room = draft.room;
    if (room == null) return;
    ref.read(adsProvider.notifier).warmUpInterstitial();
    ref
        .read(sessionControllerProvider.notifier)
        .start(
          room: room,
          minutes: draft.minutes,
          deepPreset: draft.deepPreset,
        );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SessionScreen()),
    );
  }

  /// Melanjutkan sesi yang masih terbuka tanpa menghitung checklist ulang.
  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    ref.read(adsProvider.notifier).warmUpInterstitial();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SessionScreen()),
    );
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Throw this session away?'),
        content: const Text(
          'The timer and every step you ticked are dropped and nothing is '
          'saved to your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Throw away'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(sessionControllerProvider.notifier).discard();
  }

  /// Rutinitas cepat memakai peluncur yang sama dengan layar Routines supaya
  /// pemeriksaan "sudah ada sesi berjalan?" hanya ada di satu tempat.
  Future<void> _startRoutine(
    BuildContext context,
    WidgetRef ref,
    CustomRoutine routine,
  ) => RoutineLauncher.start(context, ref, routine);
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.stats});

  final CleaningStats stats;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String get _date {
    final now = DateTime.now();
    return '${_weekdays[now.weekday - 1]}, ${now.day} '
        '${_months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OverlineLabel(_date),
              const SizedBox(height: 6),
              Text(
                _greeting,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _StreakChip(streak: stats.currentStreak, colors: colors),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak, required this.colors});

  final int streak;
  final CleanlyColors colors;

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? colors.accentSoft : colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? colors.accent : colors.hairline,
          width: active ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.local_fire_department : Icons.local_fire_department_outlined,
            size: 18,
            color: active ? colors.accentDeep : colors.inkFaint,
          ),
          const SizedBox(width: 6),
          Text(
            active ? '$streak day${streak == 1 ? '' : 's'}' : 'Start',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: active ? colors.accentDeep : colors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu sesi yang belum ditutup: hitung mundur yang masih berjalan, atau
/// sesi yang selesai ketika aplikasi sedang tidak aktif.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.session,
    required this.onContinue,
    required this.onDiscard,
  });

  final ActiveSession session;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final family = colors.accentFor(session.roomSpec.accent);
    final finished = session.status == SessionStatus.finished;
    final detail = finished
        ? '${session.completedCount} of ${session.totalCount} steps ticked — '
              'save it to keep your streak'
        : '${session.timeLabel} left · '
              '${session.completedCount} of ${session.totalCount} steps ticked';

    return SoftCard(
      color: family.soft,
      borderColor: family.base,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                finished
                    ? Icons.emoji_events_outlined
                    : Icons.timelapse_rounded,
                size: 20,
                color: family.deep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  finished
                      ? '${session.roomSpec.label} session is finished'
                      : '${session.roomSpec.label} session in progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: family.deep),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: family.deep),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: family.deep,
                    minimumSize: const Size(48, 46),
                  ),
                  child: Text(finished ? 'Save it' : 'Continue'),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onDiscard,
                child: Text(
                  'Throw away',
                  style: TextStyle(color: family.deep),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.stats});

  final CleaningStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final todayIndex = DateTime.now().weekday - 1;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: stats.cleanedToday
                      ? colors.primarySoft
                      : colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  stats.cleanedToday
                      ? Icons.check_rounded
                      : Icons.cleaning_services_outlined,
                  color: stats.cleanedToday ? colors.primaryDeep : colors.inkSoft,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.cleanedToday ? 'Cleaned today' : 'Nothing yet today',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats.cleanedToday
                          ? '${stats.todayMinutes} minutes · '
                                '${stats.totalSessions} sessions all time'
                          : 'A 5-minute reset is enough to keep the streak.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WeekStrip(
            minutesByDay: stats.weekMinutesByDay,
            todayIndex: todayIndex,
          ),
          const SizedBox(height: 12),
          Text(
            stats.weekMinutes > 0
                ? '${stats.weekMinutes} minutes this week'
                : 'This week is wide open.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
          ),
          // Nada mengajak, bukan menghakimi: hanya muncul setelah dua hari
          // benar-benar terlewat.
          if (!stats.cleanedToday && (stats.daysSinceLastSession(DateTime.now()) ?? 0) >= 2) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.wb_twilight_rounded,
                  size: 16,
                  color: colors.primaryDeep,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'It has been ${stats.daysSinceLastSession(DateTime.now())} '
                    'days. A 5-minute reset is enough to start again.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.primaryDeep,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.draft});

  final SessionDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final tasks = draft.plannedTasks;
    final room = draft.room;

    if (room == null || tasks.isEmpty) {
      return SoftCard(
        color: colors.surfaceMuted,
        borderColor: colors.surfaceMuted,
        elevated: false,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.touch_app_outlined, size: 18, color: colors.inkFaint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pick a room and Cleanly writes the checklist for you.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkSoft),
              ),
            ),
          ],
        ),
      );
    }

    final spec = CleaningCatalog.specFor(room);
    final family = colors.accentFor(spec.accent);
    final workMinutes = (draft.plannedSeconds / 60).round();

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(spec.icon, size: 20, color: family.deep),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${spec.label} · ${tasks.length} steps · about $workMinutes min of work',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.draft,
    required this.onStart,
    this.busy = false,
  });

  final SessionDraft draft;
  final VoidCallback onStart;

  /// Ada sesi lain yang belum ditutup: memulai sesi baru akan membuangnya,
  /// jadi tombolnya dikunci dulu.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final ready = draft.canStart && !busy;
    final scheme = Theme.of(context).colorScheme;
    final gradient = [
      scheme.primary,
      Color.lerp(scheme.primary, colors.accent, 0.4) ?? scheme.primary,
    ];

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: Opacity(
            opacity: ready ? 1 : 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: ready
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: gradient,
                      )
                    : null,
                color: ready ? null : colors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ready
                    ? colors.softShadow(opacity: 0.22, blur: 20, y: 10)
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: ready ? onStart : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          busy
                              ? Icons.hourglass_bottom_rounded
                              : ready
                              ? Icons.play_arrow_rounded
                              : Icons.grid_view_rounded,
                          color: ready ? scheme.onPrimary : colors.inkFaint,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        // Label boleh memendek, tata letak tidak boleh meluap —
                        // termasuk pada ukuran huruf sistem yang besar.
                        Flexible(
                          child: Text(
                            busy
                                ? 'Session in progress'
                                : ready
                                ? 'Start ${draft.minutes}-minute clean'
                                : 'Pick a room to start',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: ready
                                      ? scheme.onPrimary
                                      : colors.inkFaint,
                                  fontSize: 15.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineQuickStart extends StatelessWidget {
  const _RoutineQuickStart({required this.routine, required this.onStart});

  final CustomRoutine routine;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final family = colors.accentFor(routine.roomSpec.accent);
    return SoftCard(
      onTap: onStart,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: family.soft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.playlist_play, color: family.deep, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Your routine · ${routine.tasks.length} steps · '
                  '${routine.minutes} min',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill, color: colors.primary, size: 26),
        ],
      ),
    );
  }
}
