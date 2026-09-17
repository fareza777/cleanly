import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/soft_card.dart';
import '../../state/app_settings.dart';
import '../../state/reminder_controller.dart';
import '../navigation/main_shell.dart';

/// Tiga layar pengenalan: durasi, ruangan, lalu kebiasaan.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;
  var _wantsReminder = false;
  var _saving = false;

  static const _pages = <_OnboardingCopy>[
    _OnboardingCopy(
      icon: Icons.timer_outlined,
      title: 'Little cleans that actually finish',
      body:
          'Pick 5, 10, 20 or 30 minutes. Cleanly builds the checklist for the '
          'time you have and counts down while you work.',
      footnote: 'No account. No internet needed.',
    ),
    _OnboardingCopy(
      icon: Icons.grid_view_rounded,
      title: 'Your rooms, one tap away',
      body:
          'Kitchen, bedroom, bathroom, living room — or a quick reset that '
          'touches every room in one short burst.',
      footnote: 'Checklists are tuned to the time you chose.',
    ),
    _OnboardingCopy(
      icon: Icons.local_fire_department_outlined,
      title: 'Keep the streak alive',
      body:
          'Every finished session is saved to your history with the minutes '
          'you cleaned and the steps you ticked off.',
      footnote: 'A gentle reminder is the easiest way to stay consistent.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (_wantsReminder) {
        final schedule = ref
            .read(reminderControllerProvider.notifier)
            .draftSchedule();
        await ref
            .read(reminderControllerProvider.notifier)
            .saveSchedule(schedule);
      }
      await ref.read(settingsProvider.notifier).completeOnboarding();
    } catch (_) {
      // Onboarding tidak boleh buntu karena penyimpanan preferensi gagal.
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => _OnboardingPage(
                  copy: _pages[index],
                  showReminderOption: index == _pages.length - 1,
                  reminderOn: _wantsReminder,
                  onReminderChanged: (value) =>
                      setState(() => _wantsReminder = value),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _pages.length; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: index == _page ? 26 : 8,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? colors.primary
                                : colors.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _next,
                      child: Text(
                        _isLast ? 'Start cleaning' : 'Continue',
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

class _OnboardingCopy {
  const _OnboardingCopy({
    required this.icon,
    required this.title,
    required this.body,
    required this.footnote,
  });

  final IconData icon;
  final String title;
  final String body;
  final String footnote;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.copy,
    required this.showReminderOption,
    required this.reminderOn,
    required this.onReminderChanged,
  });

  final _OnboardingCopy copy;
  final bool showReminderOption;
  final bool reminderOn;
  final ValueChanged<bool> onReminderChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final gradient = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradient,
                  Color.lerp(gradient, colors.accent, 0.4) ?? gradient,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: colors.softShadow(opacity: 0.2, blur: 26, y: 12),
            ),
            child: Icon(copy.icon, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 30),
          Text(copy.title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 14),
          Text(
            copy.body,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.inkSoft),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.inkFaint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy.footnote,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ),
            ],
          ),
          if (showReminderOption) ...[
            const SizedBox(height: 24),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: colors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily reminder at 09:00',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You can change or remove it later in Settings.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(value: reminderOn, onChanged: onReminderChanged),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
