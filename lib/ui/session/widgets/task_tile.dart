import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/cleaning_session.dart';

/// Satu baris checklist.
///
/// Petunjuk pengerjaan tidak diulang di sini: ia sudah muncul di kartu
/// "UP NEXT", sehingga daftar tetap tenang dan mudah dipindai.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.isNext,
    required this.accent,
    required this.onToggle,
  });

  final SessionTask task;
  final bool isNext;
  final AccentFamily accent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final done = task.done;
    final highlighted = isNext && !done;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      checked: done,
      label: task.title,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: highlighted ? accent.soft : colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted
                  ? accent.base
                  : done
                  ? colors.surfaceMuted
                  : colors.hairline,
              width: highlighted ? 1.6 : 1,
            ),
            boxShadow: highlighted ? colors.softShadow(opacity: 0.08) : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CheckMark(done: done, accent: accent, scheme: scheme),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: done
                                      ? colors.inkFaint
                                      : colors.ink,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: colors.inkFaint,
                                ),
                          ),
                          if (highlighted) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Next up',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: accent.deep,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _EstimateChip(
                      seconds: task.seconds,
                      done: done,
                      accent: accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({
    required this.done,
    required this.accent,
    required this.scheme,
  });

  final bool done;
  final AccentFamily accent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: done ? accent.base : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: done ? accent.base : colors.hairline,
          width: 1.8,
        ),
      ),
      child: done
          ? Icon(Icons.check_rounded, size: 17, color: scheme.onPrimary)
          : null,
    );
  }
}

class _EstimateChip extends StatelessWidget {
  const _EstimateChip({
    required this.seconds,
    required this.done,
    required this.accent,
  });

  final int seconds;
  final bool done;
  final AccentFamily accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final minutes = seconds / 60;
    final label = minutes < 1
        ? '<1 min'
        : minutes == minutes.roundToDouble()
        ? '${minutes.round()} min'
        : '${minutes.toStringAsFixed(1)} min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: done ? colors.surfaceMuted : colors.canvas,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: done ? colors.inkFaint : colors.inkSoft,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
