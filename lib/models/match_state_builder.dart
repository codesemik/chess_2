import 'piece_library.dart';
import '../controllers/board_controller.dart';

/// Bir oyuncunun Firestore'daki HAM diziliş + seviye verisinden, o
/// oyuncunun kendi canlı [FormationService]/[CardLevelService]
/// singleton'larına HİÇ dokunmadan bir taş seti kurar. Eşleşme sırasında
/// hem "ben" hem "rakip" için kullanılır — rakibin verisi zaten yerel
/// singleton'larda değil, doğrudan Firestore'dan okunuyor olacak.
class FormationSnapshot {
  final List<Piece> pawns;
  final Piece dpsLeft;
  final Piece dpsRight;
  final Piece queen;
  final Piece king;

  FormationSnapshot({
    required this.pawns,
    required this.dpsLeft,
    required this.dpsRight,
    required this.queen,
    required this.king,
  });

  factory FormationSnapshot.fromRaw(
    Map<String, dynamic>? formationJson,
    Map<String, dynamic>? cardLevelsJson,
  ) {
    final levels = <String, int>{};
    final rawLevels = cardLevelsJson?['levels'];
    if (rawLevels is Map) {
      rawLevels.forEach((k, v) {
        if (v is num) levels[k.toString()] = v.toInt();
      });
    }
    int levelOf(String id) => levels[id] ?? 1;

    Piece resolve(String? id, Piece fallback) {
      final template = (id == null) ? fallback : PieceLibrary.byId(id);
      return template.copyWith(level: levelOf(template.id));
    }

    final rawPawnIds = formationJson?['pawnSlotIds'];
    final pawnIds = (rawPawnIds is List) ? rawPawnIds.map((e) => e.toString()).toList() : null;
    final pawns = List<Piece>.generate(4, (i) {
      final id = (pawnIds != null && i < pawnIds.length) ? pawnIds[i] : null;
      return resolve(id, PieceLibrary.pawn);
    });

    return FormationSnapshot(
      pawns: pawns,
      dpsLeft: resolve(formationJson?['dpsLeftId'] as String?, PieceLibrary.goblin),
      dpsRight: resolve(formationJson?['dpsRightId'] as String?, PieceLibrary.skeleArcher),
      queen: resolve(formationJson?['queenId'] as String?, PieceLibrary.queen),
      king: resolve(formationJson?['kingId'] as String?, PieceLibrary.king),
    );
  }
}

/// İki oyuncunun ham Firestore verisinden (kendi cihazlarındaki servislere
/// hiç dokunmadan) bir maçın başlangıç tahta durumunu kurar ve doğrudan
/// Firestore'a yazılabilecek düz bir haritaya çevirir.
Map<String, dynamic> buildInitialMatchStateJson({
  required Map<String, dynamic>? whiteFormationJson,
  required Map<String, dynamic>? whiteCardLevelsJson,
  required Map<String, dynamic>? blackFormationJson,
  required Map<String, dynamic>? blackCardLevelsJson,
}) {
  final white = FormationSnapshot.fromRaw(whiteFormationJson, whiteCardLevelsJson);
  final black = FormationSnapshot.fromRaw(blackFormationJson, blackCardLevelsJson);

  final controller = BoardController();
  controller.initBoardRaw(
    whitePawns: white.pawns,
    whiteDpsLeft: white.dpsLeft,
    whiteDpsRight: white.dpsRight,
    whiteQueen: white.queen,
    whiteKing: white.king,
    blackPawns: black.pawns,
    blackDpsLeft: black.dpsLeft,
    blackDpsRight: black.dpsRight,
    blackQueen: black.queen,
    blackKing: black.king,
  );
  return controller.toMatchStateJson();
}
