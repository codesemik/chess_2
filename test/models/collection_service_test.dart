import 'package:flutter_test/flutter_test.dart';
import 'package:chess_2/models/collection_service.dart';
import 'package:chess_2/models/piece_library.dart';

void main() {
  // CollectionService bir singleton (uygulama ömrü boyunca tek örnek).
  // Testler arası state sızıntısını önlemek için her testten önce sıfırla.
  setUp(() {
    CollectionService.instance.resetForTest();
  });

  group('Başlangıç durumu', () {
    test('oyuncu 3000 altınla başlar', () {
      expect(CollectionService.instance.gold, 3000);
    });

    test('tüm temel kartlara ve 3 hediye karta sahiptir', () {
      final c = CollectionService.instance;
      expect(c.isOwned(PieceLibrary.pawn), isTrue);
      expect(c.isOwned(PieceLibrary.king), isTrue);
      expect(c.isOwned(PieceLibrary.goblin), isTrue);
      expect(c.isOwned(PieceLibrary.skeleArcher), isTrue);
      expect(c.isOwned(PieceLibrary.golem), isTrue);
    });

    test('mağaza kartlarına henüz sahip değildir', () {
      expect(CollectionService.instance.isOwned(PieceLibrary.mancinik), isFalse);
      expect(CollectionService.instance.isOwned(PieceLibrary.zamanLordu), isFalse);
    });
  });

  group('buy()', () {
    test('yeterli altın varsa satın alır ve altını düşer', () {
      final c = CollectionService.instance;
      final price = priceForRarity(PieceLibrary.mancinik.rarity); // rare = 250
      final result = c.buy(PieceLibrary.mancinik);
      expect(result, isTrue);
      expect(c.isOwned(PieceLibrary.mancinik), isTrue);
      expect(c.gold, 3000 - price);
    });

    test('yetersiz altınla satın almayı reddeder, altını değiştirmez', () {
      final c = CollectionService.instance;
      c.gold = 10; // mythic kart (2000+) için yetersiz
      final result = c.buy(PieceLibrary.zamanLordu);
      expect(result, isFalse);
      expect(c.isOwned(PieceLibrary.zamanLordu), isFalse);
      expect(c.gold, 10);
    });

    test('zaten sahip olunan bir kartı tekrar "satın almak" altın harcamaz', () {
      final c = CollectionService.instance;
      final goldBefore = c.gold;
      final result = c.buy(PieceLibrary.pawn); // zaten başlangıç kartı
      expect(result, isTrue);
      expect(c.gold, goldBefore);
    });

    test('mythic bir kartın tam fiyatı 1600 altındır', () {
      expect(priceForRarity(Rarity.mythic), 1600);
    });
  });

  group('spendGold() / addGold()', () {
    test('spendGold yeterli bakiyede altını düşürür ve true döner', () {
      final c = CollectionService.instance;
      final result = c.spendGold(500);
      expect(result, isTrue);
      expect(c.gold, 2500);
    });

    test('spendGold yetersiz bakiyede false döner, altını değiştirmez', () {
      final c = CollectionService.instance;
      final result = c.spendGold(999999);
      expect(result, isFalse);
      expect(c.gold, 3000);
    });

    test('addGold altını artırır (klan bağışı / görev ödülü senaryosu)', () {
      final c = CollectionService.instance;
      c.addGold(250);
      expect(c.gold, 3250);
    });
  });

  group('toJson / restoreFromJson (bulut senkronu)', () {
    test('durum kayıpsız kaydedilip geri yüklenir', () {
      final c = CollectionService.instance;
      c.buy(PieceLibrary.mancinik);
      c.spendGold(100);
      final snapshot = c.toJson();

      c.resetForTest(); // farklı bir cihazdan taze açılış simülasyonu
      c.restoreFromJson(snapshot);

      expect(c.gold, snapshot['gold']);
      expect(c.isOwned(PieceLibrary.mancinik), isTrue);
    });
  });
}
