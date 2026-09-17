import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tujuh titik untuk minggu berjalan: hari yang sudah dibersihkan terisi
/// penuh, hari ini diberi cincin.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.minutesByDay,
    required this.todayIndex,
    this.accent,
  });

  /// Senin sampai Minggu.
  final List<int> minutesByDay;
  final int todayIndex;
  final Color? accent;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final active = accent ?? colors.primary;
    return Row(
      children: [
        for (var index = 0; index < _labels.length; index++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: (minutesByDay[index] > 0)
                          ? active
                          : colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(11),
                      border: index == todayIndex
                          ? Border.all(color: colors.ink, width: 1.6)
                          : null,
                    ),
                    child: Center(
                      child: minutesByDay[index] > 0
                          ? Icon(
                              Icons.check_rounded,
                              size: 17,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : Text(
                              '—',
                              style: TextStyle(
                                color: colors.inkFaint,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _labels[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: index == todayIndex ? colors.ink : colors.inkFaint,
                      letterSpacing: 0,
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
