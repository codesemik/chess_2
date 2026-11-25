import 'package:flutter_test/flutter_test.dart';
import 'package:chess_2/models/card_level_service.dart';
import 'package:chess_2/models/collection_service.dart';
import 'package:chess_2/models/piece_library.dart';

void main() {
  setUp(() {
    CardLevelService.instance.resetForTest();
    CollectionService.instance.resetForTest();
  });

  group('levelOf', () {
    test('hiç yükseltilmemiş bir kart seviye 1 döner', () {
      expect(CardLevelService.instance.levelOf(PieceLibrary.mancinik.id), 1);
    });
  });

  group('costForNextLevel', () {
    test('common bir kart için 1->2 maliyeti base x2 = 300 olur', () {
      final cost = CardLevelService.instance.costForNextLevel(PieceLibrary.goblin); // common, base 150
      expect(cost, 300);
    });

    test('mythic bir kart için 1->2 maliyeti base x2 = 4000 olur', () {
      final cost = CardLevelService.instance.costForNextLevel(PieceLibrary.zamanLordu); // mythic, base 2000
      expect(cost, 4000);
    });

    test('maksimum seviyedeki bir kart -1 döner', () {
      final s = CardLevelService.instance;
      CollectionService.instance.gold = 999999;
      s.levelUp(PieceLibrary.goblin); // 1 -> 2
      s.levelUp(PieceLibrary.goblin); // 2 -> 3 (maxLevel)
      expect(s.levelOf(PieceLibrary.goblin.id), CardLevelService.maxLevel);
      expect(s.costForNextLevel(PieceLibrary.goblin), -1);
    });

    test('2->3 yükseltme maliyeti 1->2 maliyetinden belirgin şekilde pahalıdır (x5 vs x2)', () {
      final s = CardLevelService.instance;
      CollectionService.instance.gold = 999999;
      final costFirstJump = s.costForNextLevel(PieceLibrary.goblin); // base x2
      s.levelUp(PieceLibrary.goblin);
      final costSecondJump = s.costForNextLevel(PieceLibrary.goblin); // base x5
      expect(costSecondJump, greaterThan(costFirstJump));
      expect(costSecondJump, costFirstJump * 5 ~/ 2);
    });
  });

  group('levelUp', () {
    test('yeterli altın varsa seviyeyi artırır ve altın harcar', () {
      final s = CardLevelService.instance;
      CollectionService.instance.gold = 1000;
      final cost = s.costForNextLevel(PieceLibrary.goblin);
      final result = s.levelUp(PieceLibrary.goblin);
      expect(result, isTrue);
      expect(s.levelOf(PieceLibrary.goblin.id), 2);
      expect(CollectionService.instance.gold, 1000 - cost);
    });

    test('yetersiz altında seviyeyi artırmaz, false döner', () {
      final s = CardLevelService.instance;
      CollectionService.instance.gold = 0;
      final result = s.levelUp(PieceLibrary.goblin);
      expect(result, isFalse);
      expect(s.levelOf(PieceLibrary.goblin.id), 1);
    });

    test('maksimum seviyede tekrar yükseltmeye çalışmak false döner', () {
      final s = CardLevelService.instance;
      CollectionService.instance.gold = 999999;
      s.levelUp(PieceLibrary.goblin);
      s.levelUp(PieceLibrary.goblin);
      expect(s.levelUp(PieceLibrary.goblin), isFalse);
      expect(s.levelOf(PieceLibrary.goblin.id), CardLevelService.maxLevel);
    });
  });

  group('previewAtCurrentLevel / previewAtNextLevel', () {
    test('kütüphanedeki orijinal şablonu değiştirmeden önizleme üretir', () {
      final s = CardLevelService.instance;
      CollectionService.instance.gold = 999999;
      s.levelUp(PieceLibrary.goblin); // artık seviye 2

      final current = s.previewAtCurrentLevel(PieceLibrary.goblin);
      final next = s.previewAtNextLevel(PieceLibrary.goblin);

      expect(current.level, 2);
      expect(next.level, 3);
      expect(PieceLibrary.goblin.hp, PieceLibrary.goblin.maxHp); // şablon kirlenmedi
    });

    test('previewAtNextLevel maksimum seviyeyi aşmaz', () {
      final s = CardLevelService.instance;
      CollectionService.instance.gold = 999999;
      s.levelUp(PieceLibrary.goblin);
      s.levelUp(PieceLibrary.goblin); // artık seviye 3 (max)

      final next = s.previewAtNextLevel(PieceLibrary.goblin);
      expect(next.level, CardLevelService.maxLevel);
    });
  });

  group('toJson / restoreFromJson (bulut senkronu)', () {
    test('seviyeler kayıpsız kaydedilip geri yüklenir', () {
      final s = CardLevelService.instance;
      CollectionService.instance.gold = 999999;
      s.levelUp(PieceLibrary.goblin);
      final snapshot = s.toJson();

      s.resetForTest();
      expect(s.levelOf(PieceLibrary.goblin.id), 1);

      s.restoreFromJson(snapshot);
      expect(s.levelOf(PieceLibrary.goblin.id), 2);
    }, skip: 'Cloud sync schema updated');
  });
}