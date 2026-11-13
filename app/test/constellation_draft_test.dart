import 'package:constella_app/constellations/constellation_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _roundTripTests();
  test('nodeAt mengembalikan node terdekat dalam radius', () {
    const draft = ConstellationDraft(nodes: [Offset(0, 0), Offset(100, 0)]);
    expect(draft.nodeAt(const Offset(5, 5)), 0);
    expect(draft.nodeAt(const Offset(95, 0)), 1);
  });

  test('nodeAt mengembalikan null di luar radius', () {
    const draft = ConstellationDraft(nodes: [Offset(0, 0)]);
    expect(draft.nodeAt(const Offset(200, 200)), isNull);
  });

  test('nodeAt memilih yang terdekat saat dua node berdekatan', () {
    const draft = ConstellationDraft(nodes: [Offset(0, 0), Offset(20, 0)]);
    expect(draft.nodeAt(const Offset(15, 0)), 1);
  });

  test('connect mengabaikan sambungan ke diri sendiri', () {
    const draft = ConstellationDraft(nodes: [Offset(0, 0), Offset(10, 0)]);
    expect(draft.connect(0, 0).edges, isEmpty);
  });

  test('connect mengabaikan sambungan ganda terlepas dari urutan', () {
    const draft = ConstellationDraft(nodes: [Offset(0, 0), Offset(10, 0)]);
    final once = draft.connect(0, 1);
    expect(once.edges, [(0, 1)]);
    expect(once.connect(1, 0).edges, [(0, 1)]);
  });

  test('connect mengabaikan indeks di luar jangkauan', () {
    const draft = ConstellationDraft(nodes: [Offset(0, 0)]);
    expect(draft.connect(0, 5).edges, isEmpty);
    expect(draft.connect(-1, 0).edges, isEmpty);
  });

  test('undo membuang garis dulu, baru node', () {
    var draft = const ConstellationDraft()
        .addNode(const Offset(0, 0))
        .addNode(const Offset(50, 0))
        .connect(0, 1);
    expect(draft.edges, hasLength(1));

    draft = draft.undo();
    expect(draft.edges, isEmpty);
    expect(draft.nodes, hasLength(2));

    draft = draft.undo();
    expect(draft.nodes, hasLength(1));

    draft = draft.undo().undo();
    expect(draft.isEmpty, isTrue);
  });

  test('isSaveable butuh minimal satu garis', () {
    final lone = const ConstellationDraft().addNode(const Offset(0, 0));
    expect(lone.isSaveable, isFalse);
    expect(lone.addNode(const Offset(50, 0)).connect(0, 1).isSaveable, isTrue);
  });

  test('toJson memakai bentuk yang cocok untuk kolom JSONB', () {
    final draft = const ConstellationDraft()
        .addNode(const Offset(1, 2))
        .addNode(const Offset(3, 4))
        .connect(1, 0);
    expect(draft.toJson(), {
      'nodes': [
        {'x': 1.0, 'y': 2.0},
        {'x': 3.0, 'y': 4.0},
      ],
      'edges': [
        [0, 1],
      ],
      'space': 'screen',
    });
  });
}

void _roundTripTests() {
  test('fromJson mengembalikan bentuk yang sama dengan toJson', () {
    final draft = const ConstellationDraft()
        .addNode(const Offset(1, 2))
        .addNode(const Offset(3, 4))
        .addNode(const Offset(5, 6))
        .connect(0, 1)
        .connect(1, 2);
    final back = ConstellationDraft.fromJson(draft.toJson());
    expect(back.nodes, draft.nodes);
    expect(back.edges, draft.edges);
  });

  test('JSON rusak menghasilkan bentuk kosong, bukan lemparan', () {
    expect(ConstellationDraft.fromJson(const {}).isEmpty, isTrue);
    expect(
      ConstellationDraft.fromJson(const {'nodes': 'bukan list'}).isEmpty,
      isTrue,
    );
  });

  test('node yang cacat dilewati, sisanya tetap terbaca', () {
    final back = ConstellationDraft.fromJson(const {
      'nodes': [
        {'x': 1, 'y': 2},
        {'x': 'a', 'y': 2},
        {'x': 3, 'y': 4},
      ],
      'edges': [
        [0, 1],
      ],
    });
    expect(back.nodes, hasLength(2));
    expect(back.edges, [(0, 1)]);
  });

  test('garis yang menunjuk node tidak ada dibuang', () {
    final back = ConstellationDraft.fromJson(const {
      'nodes': [
        {'x': 0, 'y': 0},
      ],
      'edges': [
        [0, 9],
      ],
    });
    expect(back.edges, isEmpty);
  });
}
