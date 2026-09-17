import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/progress_ring.dart';
import '../../domain/catalog/cleaning_catalog.dart';
import '../../state/session_controller.dart';
import 'completion_screen.dart';
import 'widgets/task_tile.dart';

/// Layar kerja: hitung mundur besar, progres tugas, dan checklist yang bisa
/// dicentang sambil berjalan.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with WidgetsBindingObserver {
  /// Sesi terakhir yang pernah dirender. Dipakai supaya layar tidak berkedip
  /// kosong pada frame terakhir sebelum ditutup.
  ActiveSession? _lastRendered;

  /// Sekali saja: mencegah dua dialog "stop" bertumpuk, dan mencegah pop
  /// ganda ketika pengguna menekan tombol lebih dari sekali.
  var _finishing = false;
  var _leaving = false;
  var _confirming = false;
  var _completionScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Kembali dari latar belakang: samakan hitung mundur dengan jam dinding
  /// sekarang juga, bukan menunggu tik berikutnya.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(sessionControllerProvider.notifier).syncNow();
    }
  }

  /// Menutup sesi dan menyimpan hasilnya ke riwayat.
  Future<void> _complete() async {
    if (_finishing || _leaving) return;
    _finishing = true;
    HapticFeedback.mediumImpact();
    final record = await ref
        .read(sessionControllerProvider.notifier)
        .complete();
    if (!mounted) return;
    if (record == null) {
      _leave();
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => CompletionScreen(session: record)),
    );
  }

  /// Keluar dari layar ini tanpa menyimpan apa pun.
  ///
  /// [Navigator.pop] dipakai langsung (bukan `maybePop`) karena rute ini
  /// memasang `PopScope`: `maybePop` akan memanggil ulang penanganan back dan
  /// membuat dialog stop muncul terus tanpa pernah keluar.
  void _leave() {
    if (_leaving) return;
    setState(() => _leaving = true);
    Navigator.of(context).pop();
  }

  Future<void> _confirmDiscard() async {
    if (_confirming || _leaving || _finishing) return;
    _confirming = true;
    final session = _lastRendered;
    final done = session?.completedCount ?? 0;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop this session?'),
        content: Text(
          done == 0
              ? 'Nothing has been ticked off yet, so the timer will just be '
                    'discarded. Nothing is saved to your history.'
              : 'You ticked off $done step${done == 1 ? '' : 's'}, but stopping '
                    'early does not save to your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep cleaning'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (!mounted || leave != true) return;
    ref.read(sessionControllerProvider.notifier).discard();
    _leave();
  }

  Future<void> _finishEarly() async {
    final session = _lastRendered;
    if (session == null) return;
    if (session.allTasksDone) {
      await _complete();
      return;
    }
    final remaining = session.totalCount - session.completedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish now?'),
        content: Text(
          '$remaining step${remaining == 1 ? '' : 's'} still open and '
          '${session.timeLabel} left on the clock. You can finish and still '
          'keep this session in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _complete();
  }

  void _toggleTask(int index) {
    HapticFeedback.selectionClick();
    ref.read(sessionControllerProvider.notifier).toggleTask(index);
  }

  @override
  Widget build(BuildContext context) {
    final watched = ref.watch(sessionControllerProvider);
    if (watched != null) _lastRendered = watched;
    final session = _lastRendered;

    if (session == null) {
      // Kontroler sudah kosong: tutup layar ini sendiri kecuali kita memang
      // sedang menyimpan atau keluar.
      if (!_leaving && !_finishing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _leave();
        });
      }
      return const Scaffold(body: SizedBox.shrink());
    }

    // Timer habis (termasuk sesi yang dipulihkan setelah aplikasi ditutup):
    // tutup sesi setelah frame ini selesai, bukan di tengah proses build.
    if (session.status == SessionStatus.finished && !_completionScheduled) {
      _completionScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _complete();
      });
    }

    final colors = context.cleanly;
    final accent = colors.accentFor(session.roomSpec.accent);
    final nextTask = session.nextTask;

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _confirmDiscard,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Stop session',
          ),
          title: Text(session.roomSpec.label),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _StatusBadge(status: session.status, accent: accent),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _TimerBlock(session: session, accent: accent),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                children: [
                  if (nextTask == null)
                    _AllTickedCard(accent: accent)
                  else
                    _NextUpCard(
                      title: nextTask.title,
                      hint:
                          CleaningCatalog.taskById(nextTask.taskId)?.hint ??
                          'Take it steady — done is better than perfect.',
                      accent: accent,
                      remaining: session.remainingSeconds,
                      onDone: _complete,
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Checklist',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        '${session.completedCount} of ${session.totalCount} done',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < session.tasks.length; index++)
                    TaskTile(
                      key: ValueKey(session.tasks[index].taskId),
                      task: session.tasks[index],
                      isNext: identical(nextTask, session.tasks[index]),
                      accent: accent,
                      onToggle: () => _toggleTask(index),
                    ),
                  const SizedBox(height: 6),
                  if (_hasMoreCatalogTasks(session))
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(sessionControllerProvider.notifier)
                              .addNextCatalogTask();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add another step'),
                      ),
                    ),
                ],
              ),
            ),
            _SessionControls(
              session: session,
              accent: accent,
              onPauseToggle: () {
                HapticFeedback.selectionClick();
                final controller = ref.read(
                  sessionControllerProvider.notifier,
                );
                session.isPaused ? controller.resume() : controller.pause();
              },
              onFinish: _finishEarly,
            ),
          ],
        ),
      ),
    );
  }

  bool _hasMoreCatalogTasks(ActiveSession session) {
    final existing = {for (final task in session.tasks) task.taskId};
    return CleaningCatalog.tasksFor(
      session.room,
    ).any((spec) => !existing.contains(spec.id));
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.accent});

  final SessionStatus status;
  final AccentFamily accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final label = switch (status) {
      SessionStatus.running => 'Cleaning',
      SessionStatus.paused => 'Paused',
      SessionStatus.finished => 'Done',
    };
    final isRunning = status == SessionStatus.running;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRunning ? accent.soft : colors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isRunning ? accent.base : colors.inkFaint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isRunning ? accent.deep : colors.inkSoft,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerBlock extends StatelessWidget {
  const _TimerBlock({required this.session, required this.accent});

  final ActiveSession session;
  final AccentFamily accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final total = session.plannedSeconds;
    final totalLabel =
        '${(total ~/ 60).toString().padLeft(2, '0')}:'
        '${(total % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        children: [
          // Ring menyesuaikan tinggi layar: pada ponsel pendek ia mengecil,
          // pada layar besar tetap proporsional.
          LayoutBuilder(
            builder: (context, constraints) {
              final height = MediaQuery.sizeOf(context).height;
              final size = (height * 0.3).clamp(150.0, 224.0);
              return Stack(
                alignment: Alignment.center,
                children: [
                  ProgressRing(
                    progress: session.timeProgress,
                    size: size,
                    strokeWidth: size < 180 ? 11 : 13,
                    color: accent.base,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          session.timeLabel,
                          style: AppTheme.numeric(
                            size: size < 180 ? 38 : 46,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.isPaused
                              ? 'paused · of $totalLabel'
                              : 'of $totalLabel',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: session.isPaused
                                    ? accent.deep
                                    : colors.inkFaint,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (session.isPaused)
                    Positioned.fill(
                      child: Center(
                        child: _PauseBadge(accent: accent, size: size),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          FlatProgressBar(
            progress: session.taskProgress,
            height: 8,
            color: accent.base,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${session.completedCount} of ${session.totalCount} steps ticked',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkSoft),
                ),
              ),
              Text(
                '${session.roomSpec.label} · '
                '${(session.plannedSeconds / 60).round()} min',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PauseBadge extends StatelessWidget {
  const _PauseBadge({required this.accent, required this.size});

  final AccentFamily accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: accent.base,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pause_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'PAUSED',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.title,
    required this.hint,
    required this.accent,
    required this.remaining,
    required this.onDone,
  });

  final String title;
  final String hint;
  final AccentFamily accent;
  final int remaining;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.base.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'UP NEXT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent.deep,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (remaining == 0)
                TextButton(
                  onPressed: onDone,
                  child: Text('Finish', style: TextStyle(color: accent.deep)),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.arrow_downward_rounded, color: accent.deep),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: accent.deep),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: accent.deep),
          ),
        ],
      ),
    );
  }
}

class _AllTickedCard extends StatelessWidget {
  const _AllTickedCard({required this.accent});

  final AccentFamily accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.base.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: accent.deep),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Every step is ticked. Finish whenever the timer runs out — or '
              'stop now and keep the session.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: accent.deep),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionControls extends StatelessWidget {
  const _SessionControls({
    required this.session,
    required this.accent,
    required this.onPauseToggle,
    required this.onFinish,
  });

  final ActiveSession session;
  final AccentFamily accent;
  final VoidCallback onPauseToggle;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPauseToggle,
                icon: Icon(
                  session.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  size: 20,
                ),
                label: Text(session.isPaused ? 'Resume' : 'Pause'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onFinish,
                style: FilledButton.styleFrom(backgroundColor: accent.deep),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
