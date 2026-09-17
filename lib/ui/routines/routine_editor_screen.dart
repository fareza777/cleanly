import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/custom_routine.dart';
import '../../domain/catalog/cleaning_catalog.dart';
import '../../state/cleaning_providers.dart';

/// Editor rutinitas: nama, area, durasi, dan langkah yang dipilih sendiri.
class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({
    super.key,
    this.routine,
    this.initialRoom,
    this.initialMinutes,
    this.initialName,
    this.prefillTasks = false,
  });

  final CustomRoutine? routine;
  final CleaningRoom? initialRoom;
  final int? initialMinutes;
  final String? initialName;

  /// Mengisi daftar langkah dari katalog saat dibuka (dipakai template).
  final bool prefillTasks;

  @override
  ConsumerState<RoutineEditorScreen> createState() =>
      _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  static const _uuid = Uuid();

  late final TextEditingController _name = TextEditingController(
    text: widget.routine?.name ?? widget.initialName ?? '',
  );
  late CleaningRoom _room =
      widget.routine?.room ?? widget.initialRoom ?? CleaningRoom.kitchen;
  late int _minutes = widget.routine?.minutes ?? widget.initialMinutes ?? 10;
  late final Set<String> _selected = {
    ...?widget.routine?.taskIds,
    if (widget.routine == null && widget.prefillTasks)
      ..._suggested(_room, _minutes).map((task) => task.id),
  };
  var _saving = false;
  String? _nameError;

  bool get _isEditing => widget.routine != null;

  static List<CleaningTaskSpec> _suggested(CleaningRoom room, int minutes) =>
      room == CleaningRoom.wholeHome
      ? CleaningCatalog.homeReset(minutes: minutes)
      : CleaningCatalog.selectFor(room, minutes: minutes);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final family = colors.accentFor(CleaningCatalog.specFor(_room).accent);
    final groups = _groups();
    final selectedSeconds = CleaningCatalog.totalSeconds([
      for (final task in CleaningCatalog.tasks)
        if (_selected.contains(task.id)) task,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit routine' : 'New routine'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete routine',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OverlineLabel('Routine name'),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 48,
                  decoration: InputDecoration(
                    hintText: 'e.g. Sunday evening reset',
                    counterText: '',
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: 18),
                const OverlineLabel('Area'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final spec in CleaningCatalog.selectableRooms)
                      _SelectChip(
                        label: spec.shortLabel,
                        selected: _room == spec.room,
                        onTap: () => setState(() {
                          _room = spec.room;
                          _selected.removeWhere(
                            (id) =>
                                CleaningCatalog.taskById(id)?.room != null &&
                                _room != CleaningRoom.wholeHome &&
                                CleaningCatalog.taskById(id)!.room != _room,
                          );
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const OverlineLabel('Timer length'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in CleaningCatalog.durations)
                      _SelectChip(
                        label: '$minutes min',
                        selected: _minutes == minutes,
                        onTap: () => setState(() => _minutes = minutes),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selected.length} steps selected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'About ${(selectedSeconds / 60).round()} min of work · '
                      'timer $_minutes min',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _loadSuggestion,
                icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                label: const Text('Suggest'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
              child: OverlineLabel(group.label),
            ),
            for (final task in group.tasks) _TaskOption(
              task: task,
              selected: _selected.contains(task.id),
              accent: family,
              showRoom: _room == CleaningRoom.wholeHome,
              onToggle: () => setState(() {
                if (!_selected.remove(task.id)) _selected.add(task.id);
              }),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'Save changes' : 'Create routine'),
          ),
        ),
      ),
    );
  }

  List<_TaskGroup> _groups() {
    if (_room == CleaningRoom.wholeHome) {
      return [
        for (final spec in CleaningCatalog.selectableRooms)
          if (!spec.isWholeHome)
            _TaskGroup(
              label: spec.label,
              tasks: CleaningCatalog.tasksFor(spec.room),
            ),
      ];
    }
    const labels = {1: 'Quick wins', 2: 'Standard clean', 3: 'Deep clean'};
    return [
      for (final tier in const [1, 2, 3])
        _TaskGroup(
          label: labels[tier]!,
          tasks: [
            for (final task in CleaningCatalog.tasksFor(_room))
              if (task.tier == tier) task,
          ],
        ),
    ];
  }

  void _loadSuggestion() {
    final suggested = _suggested(_room, _minutes);
    setState(() {
      _selected
        ..clear()
        ..addAll([for (final task in suggested) task.id]);
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give this routine a name.');
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one step.')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });
    final routine = CustomRoutine(
      id: widget.routine?.id ?? _uuid.v4(),
      name: name,
      room: _room,
      minutes: _minutes,
      taskIds: [
        for (final task in CleaningCatalog.tasks)
          if (_selected.contains(task.id)) task.id,
      ],
      createdAt: widget.routine?.createdAt ?? DateTime.now(),
      isAtHome: widget.routine?.isAtHome ?? false,
    );
    try {
      await ref.read(cleaningRepositoryProvider).saveRoutine(routine);
      ref.invalidate(routinesProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine could not be saved. Try again.')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final routine = widget.routine;
    if (routine == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this routine?'),
        content: Text(routine.name),
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
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}

class _TaskGroup {
  const _TaskGroup({required this.label, required this.tasks});

  final String label;
  final List<CleaningTaskSpec> tasks;
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.primarySoft : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : colors.hairline,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? colors.primaryDeep : colors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskOption extends StatelessWidget {
  const _TaskOption({
    required this.task,
    required this.selected,
    required this.accent,
    required this.showRoom,
    required this.onToggle,
  });

  final CleaningTaskSpec task;
  final bool selected;
  final AccentFamily accent;
  final bool showRoom;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final minutes = task.seconds / 60;
    final label = minutes < 1
        ? '<1 min'
        : '${minutes == minutes.roundToDouble() ? minutes.round() : minutes.toStringAsFixed(1)} min';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        checked: selected,
        label: task.title,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              decoration: BoxDecoration(
                color: selected ? accent.soft : colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? accent.base : colors.hairline,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? accent.base : colors.inkFaint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: selected ? accent.deep : colors.ink,
                              ),
                        ),
                        if (showRoom) ...[
                          const SizedBox(height: 2),
                          Text(
                            CleaningCatalog.specFor(task.room).label,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.inkFaint,
                                  letterSpacing: 0,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.inkFaint,
                      letterSpacing: 0,
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
