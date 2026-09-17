import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/cleaning_schedule.dart';
import '../../domain/catalog/cleaning_catalog.dart';
import '../../state/cleaning_providers.dart';
import '../../state/reminder_controller.dart';

/// Jadwal harian atau mingguan dengan pengingat lokal.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.cleanly;
    final schedules = ref.watch(schedulesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Cleaning schedule')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Pick a rhythm and Cleanly nudges you with a local notification. '
            'Nothing leaves your phone.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
          const SizedBox(height: 22),
          if (schedules.isEmpty)
            const _NoSchedule()
          else
            for (final schedule in schedules) ...[
              _ScheduleCard(
                schedule: schedule,
                onToggle: (value) => _toggle(context, ref, schedule, value),
                onEdit: () => _openEditor(context, ref, schedule: schedule),
                onDelete: () => _delete(context, ref, schedule),
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add_alarm_outlined, size: 20),
              label: const Text('Add a schedule'),
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            color: colors.surfaceMuted,
            borderColor: colors.surfaceMuted,
            elevated: false,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.inkFaint),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cleanly cannot pop a notification while notifications are '
                    'blocked for the app in system settings. The schedule still '
                    'saves, so turn the permission on and it will work.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    CleaningSchedule schedule,
    bool value,
  ) async {
    final result = await ref
        .read(reminderControllerProvider.notifier)
        .saveSchedule(schedule.copyWith(enabled: value));
    if (!context.mounted) return;
    _showMessage(context, ref, result);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CleaningSchedule schedule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this schedule?'),
        content: Text(schedule.summary),
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
    final result = await ref
        .read(reminderControllerProvider.notifier)
        .deleteSchedule(schedule.id);
    if (!context.mounted) return;
    _showMessage(context, ref, result);
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CleaningSchedule? schedule,
  }) async {
    final controller = ref.read(reminderControllerProvider.notifier);
    final draft = controller.draftSchedule(initial: schedule);
    final saved = await showModalBottomSheet<CleaningSchedule>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ScheduleEditorSheet(
        initial: draft,
        isEditing: schedule != null,
      ),
    );
    if (saved == null || !context.mounted) return;
    final result = await controller.saveSchedule(saved);
    if (!context.mounted) return;
    _showMessage(context, ref, result);
  }

  void _showMessage(
    BuildContext context,
    WidgetRef ref,
    ReminderResult result,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(reminderControllerProvider.notifier).messageFor(result),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final CleaningSchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final family = colors.accentFor(schedule.roomSpec.accent);
    return SoftCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: family.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              schedule.cadence == ScheduleCadence.daily
                  ? Icons.today_outlined
                  : Icons.event_repeat_outlined,
              color: family.deep,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  schedule.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
                if (schedule.enabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Next: '
                      '${schedule.nextOccurrenceLabel(now: DateTime.now())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: family.deep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: schedule.enabled,
            onChanged: onToggle,
          ),
          IconButton(
            tooltip: 'Delete schedule',
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: colors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSchedule extends StatelessWidget {
  const _NoSchedule();

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_available_outlined, color: colors.primary, size: 26),
          const SizedBox(height: 12),
          Text(
            'No schedule yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Most people keep one short daily reset and one longer weekly job. '
            'Add yours below.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _ScheduleEditorSheet extends StatefulWidget {
  const _ScheduleEditorSheet({required this.initial, required this.isEditing});

  final CleaningSchedule initial;
  final bool isEditing;

  @override
  State<_ScheduleEditorSheet> createState() => _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends State<_ScheduleEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.initial.title,
  );
  late CleaningSchedule _draft = widget.initial;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        4,
        22,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? 'Edit schedule' : 'New schedule',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            const OverlineLabel('Reminder name'),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              maxLength: 44,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Quick reset before bed',
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),
            const OverlineLabel('How often'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _OptionButton(
                    label: 'Every day',
                    icon: Icons.today_outlined,
                    selected: _draft.cadence == ScheduleCadence.daily,
                    onTap: () => setState(
                      () => _draft = _draft.copyWith(
                        cadence: ScheduleCadence.daily,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OptionButton(
                    label: 'Weekly',
                    icon: Icons.event_repeat_outlined,
                    selected: _draft.cadence == ScheduleCadence.weekly,
                    onTap: () => setState(
                      () => _draft = _draft.copyWith(
                        cadence: ScheduleCadence.weekly,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_draft.cadence == ScheduleCadence.weekly) ...[
              const SizedBox(height: 18),
              const OverlineLabel('Day'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var day = 1; day <= 7; day++)
                    _SmallChip(
                      label: CleaningSchedule.weekdayNames[day - 1].substring(0, 3),
                      selected: _draft.weekday == day,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(weekday: day),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            const OverlineLabel('Time'),
            const SizedBox(height: 10),
            _OptionButton(
              label: 'Remind me at ${_draft.timeLabel}',
              icon: Icons.alarm_outlined,
              selected: false,
              onTap: _pickTime,
            ),
            const SizedBox(height: 18),
            const OverlineLabel('Area'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final spec in CleaningCatalog.selectableRooms)
                  _SmallChip(
                    label: spec.shortLabel,
                    selected: _draft.room == spec.room,
                    onTap: () => setState(
                      () => _draft = _draft.copyWith(room: spec.room),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const OverlineLabel('Session length'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in CleaningCatalog.durations)
                  _SmallChip(
                    label: '$minutes min',
                    selected: _draft.minutes == minutes,
                    onTap: () => setState(
                      () => _draft = _draft.copyWith(minutes: minutes),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Cleanly asks for notification permission the first time you save '
              'a schedule that is on.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(widget.isEditing ? 'Save changes' : 'Save schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _draft.hour, minute: _draft.minute),
    );
    if (picked == null) return;
    setState(
      () => _draft = _draft.copyWith(
        hour: picked.hour,
        minute: picked.minute,
      ),
    );
  }

  void _save() {
    final title = _title.text.trim();
    Navigator.of(context).pop(
      _draft.copyWith(
        title: title.isEmpty ? 'Time for a quick reset' : title,
        enabled: true,
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colors.primarySoft : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : colors.hairline,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.inkSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? colors.primaryDeep : colors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colors.primarySoft : colors.surface,
            borderRadius: BorderRadius.circular(13),
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
