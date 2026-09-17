import '../../domain/catalog/cleaning_catalog.dart';

/// Rutinitas pembersihan buatan pengguna: nama, area, dan langkah pilihan
/// sendiri. Langkah disimpan sebagai daftar id katalog sehingga perkiraan
/// waktunya selalu mengikuti katalog terbaru.
class CustomRoutine {
  const CustomRoutine({
    required this.id,
    required this.name,
    required this.room,
    required this.minutes,
    required this.taskIds,
    required this.createdAt,
    this.isAtHome = false,
  });

  final String id;
  final String name;
  final CleaningRoom room;

  /// Durasi timer yang dipakai saat rutinitas ini dimulai.
  final int minutes;
  final List<String> taskIds;
  final DateTime createdAt;

  /// Rutinitas yang ditandai "di rumah" bisa dibuka sekali tekan dari Home.
  final bool isAtHome;

  RoomSpec get roomSpec => CleaningCatalog.specFor(room);

  /// Langkah lengkap; id yang tidak dikenal katalog diabaikan agar data lama
  /// tidak membuat editor gagal dibuka.
  List<CleaningTaskSpec> get tasks => [
    for (final id in taskIds) ?CleaningCatalog.taskById(id),
  ];

  int get estimatedSeconds => CleaningCatalog.totalSeconds(tasks);

  CustomRoutine copyWith({
    String? name,
    CleaningRoom? room,
    int? minutes,
    List<String>? taskIds,
    bool? isAtHome,
  }) => CustomRoutine(
    id: id,
    name: name ?? this.name,
    room: room ?? this.room,
    minutes: minutes ?? this.minutes,
    taskIds: taskIds ?? this.taskIds,
    createdAt: createdAt,
    isAtHome: isAtHome ?? this.isAtHome,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'room': room.name,
    'minutes': minutes,
    'task_ids': taskIds.join(','),
    'is_at_home': isAtHome ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  static CustomRoutine fromRow(Map<String, Object?> row) => CustomRoutine(
    id: row['id']! as String,
    name: row['name']! as String,
    room: parseRoomName(row['room'] as String?),
    minutes: (row['minutes'] as int?) ?? 10,
    taskIds: (row['task_ids'] as String? ?? '')
        .split(',')
        .where((id) => id.isNotEmpty)
        .toList(),
    isAtHome: (row['is_at_home'] as int?) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (row['created_at'] as int?) ?? 0,
    ),
  );
}

CleaningRoom parseRoomName(String? name) {
  for (final room in CleaningRoom.values) {
    if (room.name == name) return room;
  }
  return CleaningRoom.living;
}
