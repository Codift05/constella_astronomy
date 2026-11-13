import 'constellation_draft.dart';

/// Rasi bintang yang sudah disimpan pengguna.
class SavedConstellation {
  const SavedConstellation({
    required this.id,
    required this.name,
    required this.draft,
    required this.createdAt,
  });

  final String id;
  final String name;
  final ConstellationDraft draft;
  final DateTime createdAt;

  /// Baris untuk tabel `constellations` (docs/05-data-models.md).
  Map<String, Object?> toRow(String userId) => {
    'id': id,
    'user_id': userId,
    'name': name,
    'node_coordinates': draft.toJson(),
    'created_at': createdAt.toIso8601String(),
  };
}

/// Satu halaman hasil. [nextCursor] null berarti tidak ada halaman lagi.
class ConstellationPage {
  const ConstellationPage({required this.items, this.nextCursor});

  final List<SavedConstellation> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
