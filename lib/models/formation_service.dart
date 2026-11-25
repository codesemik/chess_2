import 'package:flutter/foundation.dart';
import 'piece_library.dart';
import 'collection_service.dart';

/// Oyuncunun maça girerken kullanacağı dizilimi (formasyonu) tutar.
/// Bu servis sadece "Kartlarım > Diziliş" sekmesinden değiştirilebilir;
/// Oyun ekranı sadece burada seçilmiş kartları maça taşır.
///
/// Düzen (4 sütun x 8 satır arenada oyuncunun kendi tarafı):
///   [DPS-Sol] [Şah] [Vezir] [DPS-Sağ]
///   [Piyon-A] [Piyon-B] [Piyon-C] [Piyon-D]
class FormationService extends ChangeNotifier {
  FormationService._internal();
  static final FormationService instance = FormationService._internal();

  String dpsLeftId = PieceLibrary.goblin.id;
  String dpsRightId = PieceLibrary.skeleArcher.id;
  String queenId = PieceLibrary.queen.id;
  String kingId = PieceLibrary.king.id;

  /// Piyon sırasındaki 4 slot (A, B, C, D). Varsayılan olarak hepsi normal Piyon;
  /// istenirse Goblin gibi hem-piyon-hem-dps rolüne sahip kartlarla değiştirilebilir.
  List<String> pawnSlotIds = List.filled(4, PieceLibrary.pawn.id, growable: false);

  Piece get dpsLeft => PieceLibrary.byId(dpsLeftId);
  Piece get dpsRight => PieceLibrary.byId(dpsRightId);
  Piece get queen => PieceLibrary.byId(queenId);
  Piece get king => PieceLibrary.byId(kingId);
  List<Piece> get pawns => pawnSlotIds.map(PieceLibrary.byId).toList();

  void setDpsLeft(String id) {
    dpsLeftId = id;
    notifyListeners();
  }

  void setDpsRight(String id) {
    dpsRightId = id;
    notifyListeners();
  }

  void setQueen(String id) {
    queenId = id;
    notifyListeners();
  }

  void setKing(String id) {
    kingId = id;
    notifyListeners();
  }

  void setPawnSlot(int index, String id) {
    final updated = List<String>.from(pawnSlotIds);
    updated[index] = id;
    pawnSlotIds = updated;
    notifyListeners();
  }

  /// Sahip olunmayan bir kart seçili kalmışsa (ör. gelecekte kart satılabilirse)
  /// otomatik olarak temel karta geri döner. Şimdilik kartlar satılamadığı için
  /// bu yalnızca bir güvenlik önlemidir.
  void sanitize() {
    final collection = CollectionService.instance;
    if (!collection.isOwnedId(dpsLeftId)) dpsLeftId = PieceLibrary.goblin.id;
    if (!collection.isOwnedId(dpsRightId)) dpsRightId = PieceLibrary.skeleArcher.id;
    if (!collection.isOwnedId(queenId)) queenId = PieceLibrary.queen.id;
    if (!collection.isOwnedId(kingId)) kingId = PieceLibrary.king.id;
    for (int i = 0; i < pawnSlotIds.length; i++) {
      if (!collection.isOwnedId(pawnSlotIds[i])) {
        final updated = List<String>.from(pawnSlotIds);
        updated[i] = PieceLibrary.pawn.id;
        pawnSlotIds = updated;
      }
    }
  }

  // ---------------------------------------------------------------------
  // BULUT SENKRONİZASYONU (Firestore) — bkz. CloudSyncService
  // ---------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'dpsLeftId': dpsLeftId,
        'dpsRightId': dpsRightId,
        'queenId': queenId,
        'kingId': kingId,
        'pawnSlotIds': pawnSlotIds,
      };

  void restoreFromJson(Map<String, dynamic> json) {
    dpsLeftId = json['dpsLeftId'] as String? ?? dpsLeftId;
    dpsRightId = json['dpsRightId'] as String? ?? dpsRightId;
    queenId = json['queenId'] as String? ?? queenId;
    kingId = json['kingId'] as String? ?? kingId;
    final pawns = json['pawnSlotIds'];
    if (pawns is List && pawns.length == pawnSlotIds.length) {
      pawnSlotIds = pawns.map((e) => e.toString()).toList();
    }
  }
}
