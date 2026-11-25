import 'package:flutter/foundation.dart';
import 'piece_library.dart';
import 'collection_service.dart';

/// Kartların seviyelenmesini yöneten servis. Az sayıda seviye vardır
/// (1-3) ve her seviye atlaması pahalıdır — bilinçli olarak zor tutuldu.
/// Seviye; can, vuruş gücü VE (varsa) özel yeteneğin gücünü artırır
/// (bkz. `Piece.copyWith` — kullanım hakkı/kalkan-kilit süresi seviyeyle
/// birebir ölçeklenir).
class CardLevelService extends ChangeNotifier {
  CardLevelService._internal();
  static final CardLevelService instance = CardLevelService._internal();

  static const int maxLevel = 3;

  final Map<String, int> _levels = {};

  int levelOf(String pieceId) => _levels[pieceId] ?? 1;

  bool isMaxLevel(Piece piece) => levelOf(piece.id) >= maxLevel;

  int _rarityBaseCost(Rarity r) {
    switch (r) {
      case Rarity.common:
        return 150;
      case Rarity.rare:
        return 300;
      case Rarity.epic:
        return 600;
      case Rarity.legendary:
        return 1100;
      case Rarity.mythic:
        return 2000;
    }
  }

  /// Bir sonraki seviyeye çıkmanın maliyeti. Maksimum seviyedeyse -1 döner.
  /// Üst seviyeler orantısız derecede pahalıdır ("biraz zor olsun").
  int costForNextLevel(Piece piece) {
    final current = levelOf(piece.id);
    if (current >= maxLevel) return -1;
    final base = _rarityBaseCost(piece.rarity);
    // 1 -> 2: base x 2   |   2 -> 3: base x 5
    final multiplier = current == 1 ? 2 : 5;
    return base * multiplier;
  }

  bool levelUp(Piece piece) {
    final cost = costForNextLevel(piece);
    if (cost < 0) return false; // zaten maksimum seviyede
    if (!CollectionService.instance.spendGold(cost)) return false;
    _levels[piece.id] = levelOf(piece.id) + 1;
    notifyListeners();
    return true;
  }

  /// [piece] şablonunun MEVCUT seviyedeki (can/vuruş yükseltilmiş) önizleme
  /// kopyasını döndürür. Kütüphanedeki orijinal şablonu asla değiştirmez.
  Piece previewAtCurrentLevel(Piece piece) =>
      piece.copyWith(level: levelOf(piece.id));

  /// [piece] şablonunun BİR SONRAKİ seviyedeki önizleme kopyasını döndürür
  /// (yükseltme ekranında "sonraki seviyede ne olacak" göstermek için).
  Piece previewAtNextLevel(Piece piece) {
    final next = (levelOf(piece.id) + 1).clamp(1, maxLevel);
    return piece.copyWith(level: next);
  }

  // ---------------------------------------------------------------------
  // BULUT SENKRONİZASYONU (Firestore) — bkz. CloudSyncService
  // ---------------------------------------------------------------------

  Map<String, dynamic> toJson() => {'levels': _levels};

  void restoreFromJson(Map<String, dynamic> json) {
    final levels = json['levels'];
    if (levels is Map) {
      _levels
        ..clear()
        ..addAll(levels.map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
    }
  }

  /// SADECE TESTLER İÇİN: tüm kart seviyelerini sıfırlar. Bu bir singleton
  /// olduğu için, testler arasında state sızıntısı olmaması adına her
  /// testin `setUp`'ında çağrılmalı.
  @visibleForTesting
  void resetForTest() {
    _levels.clear();
  }
}
