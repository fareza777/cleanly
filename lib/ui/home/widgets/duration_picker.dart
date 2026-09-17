import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/catalog/cleaning_catalog.dart';

/// Empat pilihan durasi sebagai pil besar, ditambah preset 45 menit yang
/// dibuka lewat rewarded ad.
class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.deepSelected,
    required this.deepUnlocked,
    required this.onDeepTap,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final bool deepSelected;
  final bool deepUnlocked;
  final VoidCallback onDeepTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final scheme = Theme.of(context).colorScheme;
    final gradient = [
      scheme.primary,
      Color.lerp(scheme.primary, colors.accent, 0.45) ?? scheme.primary,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final minutes in CleaningCatalog.durations)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: minutes == CleaningCatalog.durations.last ? 0 : 10,
                  ),
                  child: _DurationPill(
                    minutes: minutes,
                    isSelected: !deepSelected && selected == minutes,
                    gradient: gradient,
                    onTap: () => onSelected(minutes),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onDeepTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Icon(
                  deepUnlocked
                      ? (deepSelected
                            ? Icons.check_circle
                            : Icons.timer_outlined)
                      : Icons.lock_outline,
                  size: 17,
                  color: deepSelected ? colors.primary : colors.inkFaint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    deepSelected
                        ? 'Deep clean preset is on · ${CleaningCatalog.deepPresetMinutes} min'
                        : '${CleaningCatalog.deepPresetMinutes} min deep clean'
                              '${deepUnlocked ? '' : ' · unlock with a short ad'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: deepSelected ? colors.primaryDeep : colors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({
    required this.minutes,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  final int minutes;
  final bool isSelected;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: isSelected,
      button: true,
      label: '$minutes minutes',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  )
                : null,
            color: isSelected ? null : colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : colors.hairline,
            ),
            boxShadow: isSelected
                ? colors.softShadow(opacity: 0.2, blur: 18, y: 8)
                : null,
          ),
          child: Column(
            children: [
              Text(
                '$minutes',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: isSelected ? scheme.onPrimary : colors.ink,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'min',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? scheme.onPrimary.withValues(alpha: 0.85)
                      : colors.inkFaint,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
