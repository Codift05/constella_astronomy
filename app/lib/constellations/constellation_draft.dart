import 'dart:ui';

/// Rasi bintang yang sedang digambar pengguna di atas tangkapan kamera.
///
/// Koordinat masih dalam ruang layar (piksel logis), bukan world-space AR dan
/// bukan azimuth/altitude langit. Lihat docs/06-open-questions.md #3.
class ConstellationDraft {
  const ConstellationDraft({this.nodes = const [], this.edges = const []});

  final List<Offset> nodes;

  /// Pasangan indeks node. Selalu disimpan dengan indeks kecil lebih dulu
  /// supaya (1,2) dan (2,1) tidak tersimpan dua kali.
  final List<(int, int)> edges;

  /// Jarak maksimal sebuah sentuhan masih dianggap mengenai node.
  static const hitRadius = 36.0;

  bool get isEmpty => nodes.isEmpty;

  /// Bentuk baru dianggap layak disimpan setelah punya minimal satu garis.
  bool get isSaveable => edges.isNotEmpty;

  /// Indeks node terdekat dalam [hitRadius], atau null bila tidak ada.
  int? nodeAt(Offset point) {
    int? best;
    var bestDistance = hitRadius;
    for (var i = 0; i < nodes.length; i++) {
      final d = (nodes[i] - point).distance;
      if (d <= bestDistance) {
        best = i;
        bestDistance = d;
      }
    }
    return best;
  }

  ConstellationDraft addNode(Offset point) =>
      ConstellationDraft(nodes: [...nodes, point], edges: edges);

  /// Menyambung dua node. Sambungan ke diri sendiri dan sambungan ganda
  /// diabaikan, jadi memanggil ini berulang kali aman.
  ConstellationDraft connect(int a, int b) {
    if (a == b) return this;
    if (a < 0 || b < 0 || a >= nodes.length || b >= nodes.length) return this;
    final edge = a < b ? (a, b) : (b, a);
    if (edges.contains(edge)) return this;
    return ConstellationDraft(nodes: nodes, edges: [...edges, edge]);
  }

  /// Membatalkan langkah terakhir: garis dulu, baru node.
  ConstellationDraft undo() {
    if (edges.isNotEmpty) {
      return ConstellationDraft(
        nodes: nodes,
        edges: edges.sublist(0, edges.length - 1),
      );
    }
    if (nodes.isNotEmpty) {
      return ConstellationDraft(
        nodes: nodes.sublist(0, nodes.length - 1),
        edges: edges,
      );
    }
    return this;
  }

  /// Membaca balik apa yang ditulis [toJson]. Baris yang rusak atau dari
  /// versi lain menghasilkan bentuk kosong, bukan lemparan — satu baris buruk
  /// tidak boleh menjatuhkan seluruh daftar.
  factory ConstellationDraft.fromJson(Map<String, Object?> json) {
    final rawNodes = json['nodes'];
    final rawEdges = json['edges'];
    if (rawNodes is! List) return const ConstellationDraft();

    final nodes = <Offset>[];
    for (final n in rawNodes) {
      if (n is! Map) continue;
      final x = n['x'];
      final y = n['y'];
      if (x is num && y is num) nodes.add(Offset(x.toDouble(), y.toDouble()));
    }

    final edges = <(int, int)>[];
    if (rawEdges is List) {
      for (final e in rawEdges) {
        if (e is! List || e.length != 2) continue;
        final a = e[0];
        final b = e[1];
        if (a is! int || b is! int) continue;
        if (a < 0 || b < 0 || a >= nodes.length || b >= nodes.length) continue;
        final edge = a < b ? (a, b) : (b, a);
        if (!edges.contains(edge)) edges.add(edge);
      }
    }
    return ConstellationDraft(nodes: nodes, edges: edges);
  }

  /// Format yang dikirim ke kolom JSONB `constellations.node_coordinates`.
  Map<String, Object?> toJson() => {
    'nodes': [
      for (final n in nodes) {'x': n.dx, 'y': n.dy},
    ],
    'edges': [
      for (final (a, b) in edges) [a, b],
    ],
    'space': 'screen',
  };
}
