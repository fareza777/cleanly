import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Kartu dasar Cleanly: garis rambut 1 px, sudut besar, dan bayangan tipis
/// yang lebar sehingga terasa mengambang tanpa terlihat seperti template.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.onTap,
    this.color,
    this.gradient,
    this.borderColor,
    this.elevated = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final bool elevated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final borderRadius = BorderRadius.circular(radius);
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: colors.primary.withValues(alpha: 0.06),
        highlightColor: colors.primary.withValues(alpha: 0.04),
        child: Padding(padding: padding, child: child),
      ),
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      container: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gradient == null ? color ?? colors.surface : null,
          gradient: gradient,
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor ?? colors.hairline,
            width: 1,
          ),
          boxShadow: elevated ? colors.softShadow() : null,
        ),
        child: content,
      ),
    );
  }
}

/// Label mikro huruf besar di atas sebuah seksi.
class OverlineLabel extends StatelessWidget {
  const OverlineLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Text(
      text.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: color ?? colors.inkFaint),
    );
  }
}

/// Judul seksi dengan aksi opsional di kanan.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.inkFaint),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
