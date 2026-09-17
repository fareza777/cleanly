import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/catalog/cleaning_catalog.dart';

/// Kartu pemilihan area. Setiap ruangan punya warna aksen sendiri sehingga
/// pilihan terasa berbeda satu sama lain, bukan deretan kotak yang sama.
class RoomPicker extends StatelessWidget {
  const RoomPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CleaningRoom? selected;
  final ValueChanged<CleaningRoom> onSelected;

  @override
  Widget build(BuildContext context) {
    final rooms = CleaningCatalog.selectableRooms
        .where((spec) => !spec.isWholeHome)
        .toList();
    final reset = CleaningCatalog.specFor(CleaningRoom.wholeHome);

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Tinggi tetap, bukan rasio: rasio membuat kartu ikut memendek di
          // layar sempit sampai isinya tidak lagi muat.
          mainAxisExtent: 96,
          children: [
            for (final spec in rooms)
              _RoomCard(
                spec: spec,
                isSelected: selected == spec.room,
                onTap: () => onSelected(spec.room),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _RoomCard(
          spec: reset,
          isSelected: selected == CleaningRoom.wholeHome,
          onTap: () => onSelected(CleaningRoom.wholeHome),
          wide: true,
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.spec,
    required this.isSelected,
    required this.onTap,
    this.wide = false,
  });

  final RoomSpec spec;
  final bool isSelected;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final family = colors.accentFor(spec.accent);
    final radius = BorderRadius.circular(22);

    return Semantics(
      selected: isSelected,
      button: true,
      label: spec.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: wide ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: isSelected ? family.soft : colors.surface,
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? family.base : colors.hairline,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? colors.softShadow(opacity: 0.1, blur: 18, y: 8)
                  : colors.softShadow(opacity: 0.04),
            ),
            child: wide
                ? Row(
                    children: [
                      _RoomIcon(spec: spec, family: family, isSelected: isSelected),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              spec.label,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isSelected ? family.deep : colors.ink,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              spec.tagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.inkFaint),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: family.base, size: 20),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RoomIcon(
                            spec: spec,
                            family: family,
                            isSelected: isSelected,
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: family.base,
                              size: 20,
                            ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          spec.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isSelected ? family.deep : colors.ink,
                              ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _RoomIcon extends StatelessWidget {
  const _RoomIcon({
    required this.spec,
    required this.family,
    required this.isSelected,
  });

  final RoomSpec spec;
  final AccentFamily family;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isSelected ? family.base : family.soft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        spec.icon,
        size: 20,
        color: isSelected ? Colors.white : family.deep,
      ),
    );
  }
}
