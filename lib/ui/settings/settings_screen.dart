import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/soft_card.dart';
import '../../state/ads_provider.dart';
import '../../state/app_settings.dart';
import '../../state/cleaning_providers.dart';
import '../../state/reminder_controller.dart';
import '../schedule/schedule_screen.dart';
import 'theme_store_screen.dart';

/// Pengaturan: tampilan, pengingat, data, iklan, dan informasi.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.cleanly;
    final settings = ref.watch(settingsProvider);
    final schedules = ref.watch(schedulesProvider).valueOrNull ?? const [];
    final activeSchedules = schedules.where((s) => s.enabled).length;
    final adsConfig = ref.watch(monetizationConfigProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 6),
          Text(
            'Everything here is stored on this device.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Appearance'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Colour theme',
                  subtitle: '${settings.skin.label} · '
                      '${settings.unlockedSkins.length + 3} available',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ThemeStoreScreen(),
                    ),
                  ),
                ),
                _Divider(),
                _SettingsSwitch(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  subtitle: 'Easier on the eyes for evening cleans',
                  value: settings.darkMode,
                  onChanged: (value) =>
                      _save(context, ref, settings.copyWith(darkMode: value)),
                ),
                _Divider(),
                _SettingsSwitch(
                  icon: Icons.motion_photos_off_outlined,
                  title: 'Reduce motion',
                  subtitle: 'Turns off confetti and slide transitions',
                  value: settings.reducedMotion,
                  onChanged: (value) => _save(
                    context,
                    ref,
                    settings.copyWith(reducedMotion: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Reminders'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.event_repeat_outlined,
                  title: 'Cleaning schedule',
                  subtitle: activeSchedules == 0
                      ? 'No active schedule'
                      : '$activeSchedules active · next '
                            '${schedules.first.nextOccurrenceLabel(now: DateTime.now())}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ScheduleScreen(),
                    ),
                  ),
                ),
                _Divider(),
                _SettingsSwitch(
                  icon: Icons.notifications_active_outlined,
                  title: 'Reminders on',
                  subtitle: settings.remindersEnabled
                      ? 'Local notifications are scheduled'
                      : activeSchedules == 0
                      ? 'Add a schedule first'
                      : 'Switch on to arm your saved schedules',
                  value: settings.remindersEnabled,
                  onChanged: (value) => _toggleReminders(
                    context,
                    ref,
                    value,
                    hasSchedules: schedules.isNotEmpty,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Data'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Clear cleaning history',
              subtitle: 'Removes sessions and progress. Routines stay.',
              onTap: () => _clearHistory(context, ref),
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Ads'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _SettingsTile(
                  icon: Icons.campaign_outlined,
                  title: 'Where ads appear',
                  subtitle:
                      'Banner only on Home and History. A full-screen ad can '
                      'appear after a session ends — never while the timer runs.',
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Ad privacy options',
                  subtitle: adsConfig.hasAnyAdConfiguration
                      ? 'Change or withdraw your ad consent'
                      : 'No ad configuration in this build',
                  enabled: adsConfig.hasAnyAdConfiguration,
                  onTap: () => _showPrivacyOptions(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'About'),
          SoftCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppIdentity.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Version ${AppIdentity.version} · offline first',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cleanly keeps your checklists, routines, schedules and '
                  'history in a local database on this phone. There is no '
                  'account, no sync and no analytics on your cleaning habits.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AppSettings next,
  ) async {
    try {
      await ref.read(settingsProvider.notifier).update(next);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setting could not be saved on this device.'),
        ),
      );
    }
  }

  /// Sakelar pengingat: jadwal adalah sumber kebenarannya, jadi menyalakannya
  /// berarti memasang ulang alarm untuk jadwal yang sudah ada.
  Future<void> _toggleReminders(
    BuildContext context,
    WidgetRef ref,
    bool value, {
    required bool hasSchedules,
  }) async {
    final controller = ref.read(reminderControllerProvider.notifier);
    if (value && !hasSchedules) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ScheduleScreen()),
      );
      return;
    }
    final result = value
        ? await controller.enableAll()
        : await controller.disableAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(controller.messageFor(result))));
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cleaning history?'),
        content: const Text(
          'All saved sessions and the streaks built from them are removed. '
          'Routines and schedules stay.',
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

  Future<void> _showPrivacyOptions(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adsProvider.notifier).showPrivacyOptions();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Privacy options are not available right now.',
          ),
        ),
      );
    }
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: context.cleanly.hairline);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.inkSoft),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.inkFaint,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.inkSoft),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
