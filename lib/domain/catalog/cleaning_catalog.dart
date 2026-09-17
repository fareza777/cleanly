import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Area rumah yang bisa dibersihkan.
///
/// [wholeHome] bukan ruangan fisik, melainkan preset "quick home reset" yang
/// membagi durasi ke seluruh ruangan.
enum CleaningRoom { kitchen, bedroom, bathroom, living, wholeHome }

/// Satu langkah pembersihan yang punya perkiraan waktu sendiri.
///
/// [tier] menentukan kapan langkah ini muncul:
/// 1 = kemenangan cepat yang selalu dipakai, 2 = pembersihan standar,
/// 3 = pembersihan menyeluruh untuk sesi panjang.
@immutable
class CleaningTaskSpec {
  const CleaningTaskSpec({
    required this.id,
    required this.room,
    required this.title,
    required this.hint,
    required this.seconds,
    required this.tier,
  });

  final String id;
  final CleaningRoom room;
  final String title;
  final String hint;
  final int seconds;
  final int tier;
}

/// Deskripsi tampilan sebuah area.
@immutable
class RoomSpec {
  const RoomSpec({
    required this.room,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.accent,
    required this.tagline,
  });

  final CleaningRoom room;
  final String label;
  final String shortLabel;
  final IconData icon;
  final CleanlyAccent accent;
  final String tagline;

  bool get isWholeHome => room == CleaningRoom.wholeHome;
}

/// Katalog lengkap: 4 area, masing-masing 3 langkah cepat, 4 standar, dan
/// 3–4 menyeluruh. Perkiraan waktu sengaja dibuat realistis supaya daftar
/// untuk sesi 5 menit benar-benar selesai dalam 5 menit.
class CleaningCatalog {
  CleaningCatalog._();

  /// Empat area fisik. Quick Home Reset ditangani terpisah karena ia bukan
  /// ruangan, melainkan preset lintas ruangan.
  static const rooms = <RoomSpec>[
    RoomSpec(
      room: CleaningRoom.kitchen,
      label: 'Kitchen',
      shortLabel: 'Kitchen',
      icon: Icons.soup_kitchen_outlined,
      accent: CleanlyAccent.marigold,
      tagline: 'Grease, crumbs, and the pile by the sink',
    ),
    RoomSpec(
      room: CleaningRoom.bedroom,
      label: 'Bedroom',
      shortLabel: 'Bedroom',
      icon: Icons.bed_outlined,
      accent: CleanlyAccent.iris,
      tagline: 'Calm surfaces and a bed you want to fall into',
    ),
    RoomSpec(
      room: CleaningRoom.bathroom,
      label: 'Bathroom',
      shortLabel: 'Bath',
      icon: Icons.shower_outlined,
      accent: CleanlyAccent.sky,
      tagline: 'Water marks, soap scum, and the mirror',
    ),
    RoomSpec(
      room: CleaningRoom.living,
      label: 'Living Room',
      shortLabel: 'Living',
      icon: Icons.weekend_outlined,
      accent: CleanlyAccent.jade,
      tagline: 'Cushions, clutter, and dust on the shelves',
    ),
  ];

  /// Preset yang menyentuh setiap ruangan sekaligus.
  static const wholeHomeSpec = RoomSpec(
    room: CleaningRoom.wholeHome,
    label: 'Quick Home Reset',
    shortLabel: 'Whole home',
    icon: Icons.auto_awesome_outlined,
    accent: CleanlyAccent.jade,
    tagline: 'One bite-sized win in every room',
  );

  /// Area yang bisa dipilih pengguna. Quick Home Reset di urutan terakhir
  /// karena paling masuk akal untuk durasi panjang.
  static List<RoomSpec> get selectableRooms => [...rooms, wholeHomeSpec];

  static RoomSpec specFor(CleaningRoom room) => room == CleaningRoom.wholeHome
      ? wholeHomeSpec
      : rooms.firstWhere((spec) => spec.room == room);

  static const tasks = <CleaningTaskSpec>[
    // ── Kitchen ─────────────────────────────────────────────────────────
    CleaningTaskSpec(
      id: 'kitchen.counters',
      room: CleaningRoom.kitchen,
      title: 'Clear and wipe the counters',
      hint: 'Move everything off, spray, then wipe in one direction so no streaks are left.',
      seconds: 120,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'kitchen.dishes',
      room: CleaningRoom.kitchen,
      title: 'Wash the dishes',
      hint: 'Rinse and stack as you go — the goal is an empty sink, not a perfect drainer.',
      seconds: 120,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'kitchen.sink',
      room: CleaningRoom.kitchen,
      title: 'Wipe the sink and faucet',
      hint: 'Dry the faucet last so no water spots settle on the chrome.',
      seconds: 60,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'kitchen.cabinets',
      room: CleaningRoom.kitchen,
      title: 'Wipe cabinet fronts and handles',
      hint: 'Handles collect the most grease. Start and finish there.',
      seconds: 180,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'kitchen.stove',
      room: CleaningRoom.kitchen,
      title: 'Clean the stovetop and filter',
      hint: 'Let the degreaser sit for a minute before scrubbing — less effort, same result.',
      seconds: 240,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'kitchen.trash',
      room: CleaningRoom.kitchen,
      title: 'Take out the trash and reline the bin',
      hint: 'Rinse the bin while it is empty, then line it before anything goes back in.',
      seconds: 120,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'kitchen.microwave',
      room: CleaningRoom.kitchen,
      title: 'Wipe the microwave inside and out',
      hint: 'Steam a bowl of water for two minutes and everything wipes off easily.',
      seconds: 180,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'kitchen.backsplash',
      room: CleaningRoom.kitchen,
      title: 'Degrease the backsplash and tiles',
      hint: 'Work top to bottom so drips clean themselves on the way down.',
      seconds: 360,
      tier: 3,
    ),
    CleaningTaskSpec(
      id: 'kitchen.floor',
      room: CleaningRoom.kitchen,
      title: 'Sweep and mop the floor',
      hint: 'Corners first, then the middle. Change the water before it turns grey.',
      seconds: 300,
      tier: 3,
    ),
    CleaningTaskSpec(
      id: 'kitchen.fridge',
      room: CleaningRoom.kitchen,
      title: 'Sort the fridge shelf by shelf',
      hint: 'One shelf at a time: check dates, wipe the shelf, put back only what stays.',
      seconds: 480,
      tier: 3,
    ),

    // ── Bedroom ─────────────────────────────────────────────────────────
    CleaningTaskSpec(
      id: 'bedroom.bed',
      room: CleaningRoom.bedroom,
      title: 'Make the bed',
      hint: 'Smooth the duvet, then stand the pillows up. This single step changes the room.',
      seconds: 120,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'bedroom.clothes',
      room: CleaningRoom.bedroom,
      title: 'Pick the clothes off the floor',
      hint: 'Wear-again clothes on a hook, the rest straight into the basket.',
      seconds: 120,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'bedroom.nightstand',
      room: CleaningRoom.bedroom,
      title: 'Clear the nightstand',
      hint: 'Keep only what you use in bed: lamp, book, charger.',
      seconds: 60,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'bedroom.stray',
      room: CleaningRoom.bedroom,
      title: 'Put stray items back in their homes',
      hint: 'Anything that has no home yet goes into one box to sort later.',
      seconds: 180,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'bedroom.dust',
      room: CleaningRoom.bedroom,
      title: 'Dust the surfaces and lamps',
      hint: 'A dry cloth on the lamp shades, a damp one on the wood.',
      seconds: 180,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'bedroom.air',
      room: CleaningRoom.bedroom,
      title: 'Air the room and tidy the corners',
      hint: 'Open the window wide for a few minutes — fresh air does half the work.',
      seconds: 120,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'bedroom.laundry',
      room: CleaningRoom.bedroom,
      title: 'Fold and put away the laundry',
      hint: 'Fold in batches by type; the pile disappears faster than it looks.',
      seconds: 180,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'bedroom.linen',
      room: CleaningRoom.bedroom,
      title: 'Change the bed linen',
      hint: 'Fresh sheets last: shake them out before tucking so they lie flat.',
      seconds: 360,
      tier: 3,
    ),
    CleaningTaskSpec(
      id: 'bedroom.underbed',
      room: CleaningRoom.bedroom,
      title: 'Vacuum under the bed',
      hint: 'Reach the hidden corners — that dust is what you breathe at night.',
      seconds: 300,
      tier: 3,
    ),
    CleaningTaskSpec(
      id: 'bedroom.drawer',
      room: CleaningRoom.bedroom,
      title: 'Sort one drawer properly',
      hint: 'Just one. Empty it, wipe it, and put back only what you actually wear.',
      seconds: 420,
      tier: 3,
    ),

    // ── Bathroom ────────────────────────────────────────────────────────
    CleaningTaskSpec(
      id: 'bathroom.sink',
      room: CleaningRoom.bathroom,
      title: 'Wipe the sink and counter',
      hint: 'Toothpaste marks lift off instantly while the surface is still damp.',
      seconds: 120,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'bathroom.shower',
      room: CleaningRoom.bathroom,
      title: 'Rinse the shower walls',
      hint: 'Spray, wait a minute, then rinse from the top down.',
      seconds: 120,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'bathroom.mirror',
      room: CleaningRoom.bathroom,
      title: 'Squeegee the mirror',
      hint: 'A squeegee, not a cloth — that is what keeps it spotless.',
      seconds: 60,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'bathroom.toilet',
      room: CleaningRoom.bathroom,
      title: 'Scrub the toilet',
      hint: 'Bowl first, then the outside: lid, hinges, base, and the floor around it.',
      seconds: 240,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'bathroom.screen',
      room: CleaningRoom.bathroom,
      title: 'Wipe the shower screen',
      hint: 'Spray, let it soften the soap scum, then wipe downwards.',
      seconds: 180,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'bathroom.bottles',
      room: CleaningRoom.bathroom,
      title: 'Toss empty bottles and wipe the shelf',
      hint: 'Two bottles in, one out. Keep only what is actually used.',
      seconds: 120,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'bathroom.towels',
      room: CleaningRoom.bathroom,
      title: 'Swap the towels and bath mat',
      hint: 'Fold the fresh towel in thirds so it hangs evenly.',
      seconds: 120,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'bathroom.grout',
      room: CleaningRoom.bathroom,
      title: 'Scrub the grout lines',
      hint: 'An old toothbrush and a line at a time — steady beats fast.',
      seconds: 360,
      tier: 3,
    ),
    CleaningTaskSpec(
      id: 'bathroom.showerhead',
      room: CleaningRoom.bathroom,
      title: 'Descale the showerhead',
      hint: 'Soak it in warm vinegar water and the pressure comes back.',
      seconds: 300,
      tier: 3,
    ),
    CleaningTaskSpec(
      id: 'bathroom.floor',
      room: CleaningRoom.bathroom,
      title: 'Wash the floor with disinfectant',
      hint: 'Corners and behind the toilet first, then out the door.',
      seconds: 300,
      tier: 3,
    ),

    // ── Living room ─────────────────────────────────────────────────────
    CleaningTaskSpec(
      id: 'living.cushions',
      room: CleaningRoom.living,
      title: 'Straighten the cushions',
      hint: 'Chop the corners back into shape — the sofa looks new again.',
      seconds: 90,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'living.table',
      room: CleaningRoom.living,
      title: 'Clear the coffee table',
      hint: 'Everything leaves except what you genuinely want in reach.',
      seconds: 120,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'living.throws',
      room: CleaningRoom.living,
      title: 'Fold the throw blankets',
      hint: 'Fold in thirds and drape over the arm, one per seat.',
      seconds: 90,
      tier: 1,
    ),
    CleaningTaskSpec(
      id: 'living.stray',
      room: CleaningRoom.living,
      title: 'Put away what does not belong here',
      hint: 'Carry it room by room in one trip instead of walking back and forth.',
      seconds: 180,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'living.dust',
      room: CleaningRoom.living,
      title: 'Dust the shelves, TV, and frames',
      hint: 'Microfibre first, then the screen with a dry cloth only.',
      seconds: 240,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'living.remotes',
      room: CleaningRoom.living,
      title: 'Wipe the remotes and switches',
      hint: 'The most touched objects in the room deserve a pass too.',
      seconds: 120,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'living.cables',
      room: CleaningRoom.living,
      title: 'Tidy the cables and console',
      hint: 'Group with ties, hide what you can, unplug nothing.',
      seconds: 180,
      tier: 2,
    ),
    CleaningTaskSpec(
      id: 'living.sofa',
      room: CleaningRoom.living,
      title: 'Vacuum the sofa and under the cushions',
      hint: 'Crumbs travel down. Lift the cushions and go along the seams.',
      seconds: 360,
      tier: 3,
    ),
    CleaningTaskSpec(
      id: 'living.glass',
      room: CleaningRoom.living,
      title: 'Clean the glass and windows',
      hint: 'Outside in daylight, inside in the shade — otherwise you chase streaks.',
      seconds: 300,
      tier: 3,
    ),
    CleaningTaskSpec(
      id: 'living.shelf',
      room: CleaningRoom.living,
      title: 'Deep clean one shelf or storage box',
      hint: 'Pick the messiest one. Empty, wipe, and rebuild it with less.',
      seconds: 420,
      tier: 3,
    ),
  ];

  static List<CleaningTaskSpec> tasksFor(CleaningRoom room) =>
      tasks.where((task) => task.room == room).toList(growable: false);

  static CleaningTaskSpec? taskById(String id) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Langkah untuk satu area pada durasi tertentu.
  ///
  /// Ambangnya sengaja tetap: 5 menit mendapat tiga kemenangan cepat, 10 menit
  /// menambah dua langkah standar, 20 menit menyelesaikan semua langkah
  /// standar, dan 30 menit masuk ke pembersihan menyeluruh.
  static List<CleaningTaskSpec> selectFor(
    CleaningRoom room, {
    required int minutes,
  }) {
    if (room == CleaningRoom.wholeHome) {
      return homeReset(minutes: minutes);
    }
    final all = tasksFor(room);
    final quick = all.where((task) => task.tier == 1).toList();
    final standard = all.where((task) => task.tier == 2).toList();
    final deep = all.where((task) => task.tier == 3).toList();

    if (minutes <= 3) return quick.take(1).toList();
    if (minutes <= 7) return quick;
    if (minutes <= 15) return [...quick, ...standard.take(2)];
    if (minutes <= 25) return [...quick, ...standard];
    return [...quick, ...standard, ...deep.take(3)];
  }

  /// Quick Home Reset: durasi dibagi rata ke empat ruangan sehingga setiap
  /// ruangan mendapat satu atau dua kemenangan cepat.
  static List<CleaningTaskSpec> homeReset({required int minutes}) {
    final perRoom = (minutes / 4).floor().clamp(1, 30);
    return [
      for (final spec in rooms) ...selectFor(spec.room, minutes: perRoom),
    ];
  }

  /// Total perkiraan waktu daftar, dipakai untuk menampilkan "runs about
  /// N minutes" sebelum sesi dimulai.
  static int totalSeconds(Iterable<CleaningTaskSpec> tasks) =>
      tasks.fold(0, (sum, task) => sum + task.seconds);

  /// Durasi sesi yang bisa dipilih.
  static const durations = <int>[5, 10, 20, 30];

  /// Preset "deep clean" yang dibuka lewat rewarded ad.
  static const deepPresetMinutes = 45;

  static List<CleaningTaskSpec> deepPreset(CleaningRoom room) {
    if (room == CleaningRoom.wholeHome) {
      return [for (final spec in rooms) ...tasksFor(spec.room)];
    }
    return tasksFor(room);
  }
}
