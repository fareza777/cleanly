import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/custom_routine.dart';
import '../../domain/catalog/cleaning_catalog.dart';
import '../../state/ads_provider.dart';
import '../../state/cleaning_providers.dart';
import '../../state/session_controller.dart';
import '../session/session_screen.dart';
import 'routine_editor_screen.dart';

/// Rutinitas buatan pengguna. Satu di antaranya bisa diletakkan di Home
/// sebagai tombol mulai sekali tekan.
class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.cleanly;
    final routinesAsync = ref.watch(routinesProvider);
    final routines = routinesAsync.valueOrNull ?? const <CustomRoutine>[];

    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New routine'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
          children: [
            Text('Routines', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 6),
            Text(
              'Build your own checklist for the jobs you repeat every week.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
            ),
            const SizedBox(height: 24),
            if (routinesAsync.isLoading && routines.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (routines.isEmpty)
              const _EmptyRoutines()
            else ...[
              const SectionHeader(title: 'Your routines'),
              for (final routine in routines) ...[
                _RoutineCard(
                  routine: routine,
                  onStart: () =>
                      RoutineLauncher.start(context, ref, routine),
                  onEdit: () => _openEditor(context, ref, routine: routine),
                  onToggleHome: () => _toggleHome(context, ref, routine),
                  onDelete: () => _delete(context, ref, routine),
                ),
                const SizedBox(height: 12),
              ],
            ],
            const SizedBox(height: 14),
            const SectionHeader(
              title: 'Starter templates',
              subtitle: 'Open one and tweak the steps to match your home.',
            ),
            for (final template in _templates) ...[
              _TemplateCard(
                template: template,
                onOpen: () => _openEditor(
                  context,
                  ref,
                  room: template.room,
                  minutes: template.minutes,
                  name: template.name,
                  prefill: true,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CustomRoutine? routine,
    CleaningRoom? room,
    int? minutes,
    String? name,
    bool prefill = false,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RoutineEditorScreen(
          routine: routine,
          initialRoom: room,
          initialMinutes: minutes,
          initialName: name,
          prefillTasks: prefill,
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ref.invalidate(routinesProvider);
    }
  }

  Future<void> _toggleHome(
    BuildContext context,
    WidgetRef ref,
    CustomRoutine routine,
  ) async {
    final makeHome = !routine.isAtHome;
    await ref
        .read(cleaningRepositoryProvider)
        .setHomeRoutine(makeHome ? routine.id : null);
    ref.invalidate(routinesProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          makeHome
              ? '${routine.name} now shows on Home.'
              : '${routine.name} removed from Home.',
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CustomRoutine routine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this routine?'),
        content: Text(
          '${routine.name} will be removed. Your cleaning history stays.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(cleaningRepositoryProvider).deleteRoutine(routine.id);
    ref.invalidate(routinesProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Routine deleted.')),
    );
  }
}

class _Template {
  const _Template({
    required this.name,
    required this.room,
    required this.minutes,
    required this.blurb,
  });

  final String name;
  final CleaningRoom room;
  final int minutes;
  final String blurb;
}

const _templates = <_Template>[
  _Template(
    name: 'Weekend reset',
    room: CleaningRoom.wholeHome,
    minutes: 20,
    blurb: 'One quick win in every room, start to finish.',
  ),
  _Template(
    name: 'Bathroom refresh',
    room: CleaningRoom.bathroom,
    minutes: 10,
    blurb: 'Sink, shower and mirror — the ten-minute version.',
  ),
  _Template(
    name: 'Guest-ready living room',
    room: CleaningRoom.living,
    minutes: 10,
    blurb: 'Cushions, table and dust before anyone arrives.',
  ),
  _Template(
    name: 'Kitchen wind-down',
    room: CleaningRoom.kitchen,
    minutes: 5,
    blurb: 'The after-dinner tidy, done properly.',
  ),
];

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.onStart,
    required this.onEdit,
    required this.onToggleHome,
    required this.onDelete,
  });

  final CustomRoutine routine;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onToggleHome;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final family = colors.accentFor(routine.roomSpec.accent);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      onTap: onStart,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: family.soft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(routine.roomSpec.icon, color: family.deep, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        routine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (routine.isAtHome) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ON HOME',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.primaryDeep,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${routine.tasks.length} steps · ${routine.minutes} min · '
                  '${routine.roomSpec.label}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill, color: colors.primary, size: 26),
          PopupMenuButton<String>(
            tooltip: 'Routine options',
            icon: Icon(Icons.more_vert_rounded, color: colors.inkFaint),
            onSelected: (value) => switch (value) {
              'home' => onToggleHome(),
              'edit' => onEdit(),
              _ => onDelete(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'home',
                child: Text(
                  routine.isAtHome ? 'Remove from Home' : 'Show on Home',
                ),
              ),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onOpen});

  final _Template template;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final spec = CleaningCatalog.specFor(template.room);
    final family = colors.accentFor(spec.accent);
    return SoftCard(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(spec.icon, color: family.deep, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${template.blurb} · ${template.minutes} min',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: colors.inkFaint, size: 18),
        ],
      ),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines();

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.checklist_rtl_rounded, color: colors.primary, size: 26),
          const SizedBox(height: 12),
          Text(
            'No routines yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'A routine is your own checklist for a job you repeat. Pick the '
            'steps once, then start it with one tap.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Membuka sesi pembersihan dari sebuah rutinitas.
class RoutineLauncher {
  RoutineLauncher._();

  /// Memulai rutinitas.
  ///
  /// Bila sudah ada sesi yang berjalan, pengguna ditanya dulu: menimpa sesi
  /// yang sedang berjalan tanpa bertanya berarti membuang menit yang sudah
  /// dikerjakan secara diam-diam.
  static Future<void> start(
    BuildContext context,
    WidgetRef ref,
    CustomRoutine routine,
  ) async {
    final controller = ref.read(sessionControllerProvider.notifier);
    final active = ref.read(sessionControllerProvider);
    ref.read(adsProvider.notifier).warmUpInterstitial();

    if (active != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('A session is already running'),
          content: Text(
            '${active.roomSpec.label} · ${active.timeLabel} left. Starting '
            '"${routine.name}" throws that session away without saving it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep cleaning'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start this routine'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (replace != true) {
        // Tombol "Keep cleaning" membawa pengguna ke sesi yang sedang jalan.
        await _openSession(context);
        return;
      }
    }

    controller.start(
      room: routine.room,
      minutes: routine.minutes,
      routine: routine,
    );
    if (!context.mounted) return;
    await _openSession(context);
  }

  static Future<void> _openSession(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SessionScreen()),
      );
}
