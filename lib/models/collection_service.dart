import 'package:flutter/foundation.dart';
import 'piece_library.dart';

/// Kartın mağazadaki fiyatını belirler.
int priceForRarity(Rarity r) {
  switch (r) {
    case Rarity.common:
      return 100;
    case Rarity.rare:
      return 250;
    case Rarity.epic:
      return 500;
    case Rarity.legendary:
      return 900;
    case Rarity.mythic:
      return 1600;
  }
}

/// Kullanıcının altınını ve sahip olduğu kartları tutan basit,
/// uygulama ömrü boyunca bellekte yaşayan (in-memory) bir servis.
/// ChangeNotifier olduğu için Mağaza / Kartlarım ekranları anında güncellenir.
class CollectionService extends ChangeNotifier {
  CollectionService._internal() {
    // Oyuncu; tüm temel/ücretsiz kartlara (Piyon, Vezir, Şah, At, Fil, Kale)
    // ve başlangıç hediyesi olarak Goblin, Okçu İskelet, Kaya Golem
    // kartlarına zaten sahip. Diğer tüm varyasyon kartları mağazadan açılmalı.
    _owned.addAll(PieceLibrary.starterCards.map((p) => p.id));
    _owned.addAll({
      PieceLibrary.goblin.id,
      PieceLibrary.skeleArcher.id,
      PieceLibrary.golem.id,
    });
  }
  static final CollectionService instance = CollectionService._internal();

  int gold = 3000;

  final Set<String> _owned = {};

  bool isOwned(Piece piece) => _owned.contains(piece.id);
  bool isOwnedId(String id) => _owned.contains(id);

  bool buy(Piece piece) {
    if (isOwned(piece)) return true;
    final price = priceForRarity(piece.rarity);
    if (gold < price) return false;
    gold -= price;
    _owned.add(piece.id);
    notifyListeners();
    return true;
  }

  /// [gold]'ü doğrudan değiştiren yerler (ör. Klan bağışı, görev ödülleri)
  /// bu iki metodu kullanmalı; böylece dinleyen tüm ekranlar (Mağaza'daki
  /// altın göstergesi gibi) anında güncellenir.
  bool spendGold(int amount) {
    if (gold < amount) return false;
    gold -= amount;
    notifyListeners();
    return true;
  }

  void addGold(int amount) {
    gold += amount;
    notifyListeners();
  }

  List<Piece> get ownedPieces =>
      PieceLibrary.all.where((p) => _owned.contains(p.id)).toList();

  List<Piece> ownedByRole(CardRole role) =>
      PieceLibrary.byRole(role).where((p) => _owned.contains(p.id)).toList();

  // ---------------------------------------------------------------------
  // BULUT SENKRONİZASYONU (Firestore) — bkz. CloudSyncService
  // ---------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'gold': gold,
        'owned': _owned.toList(),
      };

  /// Firestore'dan gelen veriyi bu servise uygular. `notifyListeners()`
  /// BİLEREK çağrılmaz: bu, uygulama açılışında (henüz hiçbir ekran
  /// dinlemeye başlamadan) tek seferlik bir yükleme için kullanılır.
  void restoreFromJson(Map<String, dynamic> json) {
    final g = json['gold'];
    if (g is num) gold = g.toInt();
    final owned = json['owned'];
    if (owned is List && owned.isNotEmpty) {
      _owned
        ..clear()
        ..addAll(owned.map((e) => e.toString()));
    }
  }

  /// SADECE TESTLER İÇİN: servisi başlangıç durumuna (3000 altın + temel
  /// kartlar) döndürür. Bu bir singleton olduğu için, testler arasında
  /// state sızıntısı olmaması adına her testin `setUp`'ında çağrılmalı.
  @visibleForTesting
  void resetForTest() {
    gold = 3000;
    _owned
      ..clear()
      ..addAll(PieceLibrary.starterCards.map((p) => p.id))
      ..addAll({
        PieceLibrary.goblin.id,
        PieceLibrary.skeleArcher.id,
        PieceLibrary.golem.id,
      });
  }
}
