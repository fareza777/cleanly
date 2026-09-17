import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/soft_card.dart';
import '../../state/app_settings.dart';
import '../monetization/rewarded_unlock_sheet.dart';

/// Galeri tema. Tema pertama gratis, dua terakhir dibuka dengan satu rewarded
/// ad — tidak ada pembelian dan tidak ada langganan.
class ThemeStoreScreen extends ConsumerWidget {
  const ThemeStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.cleanly;
    final settings = ref.watch(settingsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Themes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Colour themes change the accents across the whole app. Your '
            'checklists and history are untouched.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.86,
            children: [
              for (final skin in ThemeSkin.values)
                _SkinCard(
                  skin: skin,
                  dark: dark,
                  isActive: settings.skin == skin,
                  isUnlocked: settings.isSkinUnlocked(skin),
                  onTap: () => _useSkin(context, ref, skin),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Presets'),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            onTap: () => _unlockDeepPreset(context, ref),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    settings.deepPresetUnlocked
                        ? Icons.check_rounded
                        : Icons.lock_outline,
                    color: colors.accentDeep,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deep clean preset',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.deepPresetUnlocked
                            ? 'Unlocked · 45-minute checklist for any room'
                            : '45-minute checklist, unlocked with a short ad',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                      ),
                    ],
                  ),
                ),
                if (settings.deepPresetUnlocked)
                  Icon(Icons.verified_rounded, color: colors.primary, size: 20)
                else
                  Icon(
                    Icons.play_circle_outline,
                    color: colors.inkFaint,
                    size: 22,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useSkin(
    BuildContext context,
    WidgetRef ref,
    ThemeSkin skin,
  ) async {
    final settings = ref.read(settingsProvider);
    if (settings.isSkinUnlocked(skin)) {
      await _saveSkin(context, ref, settings.copyWith(skin: skin));
      return;
    }
    final earned = await showRewardedUnlockSheet(
      context,
      ref,
      title: 'Unlock ${skin.label}',
      body:
          'One short ad unlocks the ${skin.label} theme for good. You can '
          'switch between every unlocked theme whenever you like.',
      purpose: 'the ${skin.label} theme',
      onEarned: () {},
    );
    if (!earned || !context.mounted) return;
    try {
      await ref.read(settingsProvider.notifier).unlockSkin(skin);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Theme could not be saved on this device.'),
        ),
      );
    }
  }

  Future<void> _unlockDeepPreset(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.deepPresetUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already unlocked — pick it on the Home screen.'),
        ),
      );
      return;
    }
    final earned = await showRewardedUnlockSheet(
      context,
      ref,
      title: 'Deep clean preset',
      body:
          'Unlocks a 45-minute checklist that covers every step for the room '
          'you pick, including the ones most people skip.',
      purpose: 'the deep clean preset',
      onEarned: () {},
    );
    if (!earned || !context.mounted) return;
    try {
      await ref.read(settingsProvider.notifier).unlockDeepPreset();
    } catch (_) {
      // Diamkan: preset tetap bisa dipakai untuk sesi berjalan.
    }
  }

  Future<void> _saveSkin(
    BuildContext context,
    WidgetRef ref,
    AppSettings next,
  ) async {
    try {
      await ref.read(settingsProvider.notifier).update(next);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theme change could not be saved.')),
      );
    }
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.dark,
    required this.isActive,
    required this.isUnlocked,
    required this.onTap,
  });

  final ThemeSkin skin;
  final bool dark;
  final bool isActive;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final gradient = skin.gradient(dark: dark);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: isActive ? colors.primary : null,
      elevated: true,
      semanticLabel: '${skin.label} theme',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Icon(
                      isUnlocked ? Icons.check_circle : Icons.lock_outline,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  skin.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (isActive)
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
                    'ACTIVE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.primaryDeep,
                      letterSpacing: 0.8,
                    ),
                  ),
                )
              else if (!isUnlocked)
                Text(
                  'Watch ad',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.inkFaint,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
