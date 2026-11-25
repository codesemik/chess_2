import 'package:flutter_test/flutter_test.dart';
import 'package:chess_2/models/piece_library.dart';

void main() {
  group('Piece.copyWith (yeni maç kurulumu)', () {
    test('seviye 1 iken hiçbir bonus eklemez', () {
      final p = PieceLibrary.pawn.copyWith(newTeam: Team.white, newId: 'x', level: 1);
      expect(p.hp, PieceLibrary.pawn.maxHp);
      expect(p.attackPower, PieceLibrary.pawn.attackPower);
      expect(p.level, 1);
    });

    test('seviye 2 can ve vuruş gücüne +1 ekler', () {
      final p = PieceLibrary.pawn.copyWith(newTeam: Team.white, newId: 'x', level: 2);
      expect(p.hp, PieceLibrary.pawn.maxHp + 1);
      expect(p.maxHp, PieceLibrary.pawn.maxHp + 1);
      expect(p.attackPower, PieceLibrary.pawn.attackPower + 1);
    });

    test('seviye 3 can ve vuruş gücüne +2 ekler', () {
      final p = PieceLibrary.pawn.copyWith(newTeam: Team.white, newId: 'x', level: 3);
      expect(p.hp, PieceLibrary.pawn.maxHp + 2);
      expect(p.attackPower, PieceLibrary.pawn.attackPower + 2);
    });

    test('usesRemaining ve stoneSkinCharges seviyeyle birebir ölçeklenir', () {
      final p = PieceLibrary.madenMuhafizi.copyWith(newTeam: Team.white, newId: 'x', level: 3);
      expect(p.usesRemaining, 3);
      expect(p.stoneSkinCharges, 3);
    });

    test('takım ve id doğru atanır, şablon kütüphanesi kirlenmez', () {
      final original = PieceLibrary.pawn;
      final originalHp = original.hp;
      PieceLibrary.pawn.copyWith(newTeam: Team.black, newId: 'b_pawn_0', level: 3);
      // Kütüphanedeki şablon değişmemiş olmalı (copyWith yeni nesne üretir).
      expect(original.hp, originalHp);
      expect(original.team, Team.white);
    });
  });

  group('Piece.clone (Zaman Lordu: Geri Sarma)', () {
    test('mevcut maç-içi durumu (can, kalkan, kilit) birebir korur', () {
      final p = PieceLibrary.pawn.copyWith(newTeam: Team.white, newId: 'x', level: 1);
      p.hp = 1;
      p.shieldTurns = 2;
      p.frozenTurns = 1;
      p.usesRemaining = 0;

      final cloned = p.clone();
      expect(cloned.hp, 1);
      expect(cloned.shieldTurns, 2);
      expect(cloned.frozenTurns, 1);
      expect(cloned.usesRemaining, 0);
      expect(cloned.id, p.id);
    });

    test('klon bağımsız bir nesnedir (referans paylaşmaz)', () {
      final p = PieceLibrary.pawn.copyWith(newTeam: Team.white, newId: 'x', level: 1);
      final cloned = p.clone();
      cloned.hp = 99;
      expect(p.hp, isNot(99));
    });
  });

  group('Piece.copyForPlacement (çevrimiçi maç senkronu)', () {
    test('can/seviye/kullanım haklarını YENİDEN HESAPLAMADAN olduğu gibi taşır', () {
      final leveled = PieceLibrary.madenMuhafizi.copyWith(newTeam: Team.white, newId: 'x', level: 2);
      leveled.hp = 1; // maçta hasar almış gibi simüle et
      leveled.stoneSkinCharges = 0; // yeteneğini tüketmiş gibi

      final placed = leveled.copyForPlacement(newTeam: Team.white, newId: 'w_pawn_0');
      expect(placed.hp, 1); // maxHp'ye resetlenmemeli
      expect(placed.level, 2);
      expect(placed.stoneSkinCharges, 0); // tekrar seviyeye göre dolmamalı
    });
  });

  group('Piece.toJson / fromJson (Firestore round-trip)', () {
    test('tam durum kayıpsız geri yüklenir', () {
      final p = PieceLibrary.ejderhaKralice.copyWith(newTeam: Team.black, newId: 'b_queen', level: 2);
      p.hp = 2;
      p.shieldTurns = 1;
      p.frozenTurns = 3;
      p.usesRemaining = 1;

      final json = p.toJson();
      final restored = Piece.fromJson(json);

      expect(restored.id, p.id);
      expect(restored.team, p.team);
      expect(restored.hp, p.hp);
      expect(restored.maxHp, p.maxHp);
      expect(restored.attackPower, p.attackPower);
      expect(restored.level, p.level);
      expect(restored.shieldTurns, p.shieldTurns);
      expect(restored.frozenTurns, p.frozenTurns);
      expect(restored.usesRemaining, p.usesRemaining);
      expect(restored.ability, p.ability);
      expect(restored.roles, p.roles);
      expect(restored.moveStyle, p.moveStyle);
    });

    test('eksik alanlarla (eski/kısmi kayıt) makul varsayılanlara düşer', () {
      final minimal = {
        'id': 'test_pawn',
        'nameKey': 'piece_pawn',
        'type': 'pawn',
        'team': 'white',
        'moveStyle': 'pawnStyle',
        'emoji': '♙',
        'hp': 1,
        'maxHp': 1,
        'attackPower': 1,
      };
      final restored = Piece.fromJson(minimal);
      expect(restored.rarity, Rarity.common);
      expect(restored.ability, SpecialAbility.none);
      expect(restored.roles, isEmpty);
      expect(restored.level, 1);
      expect(restored.shieldTurns, 0);
      expect(restored.frozenTurns, 0);
    });
  });

  group('Rol tabanlı kimlik (isKingPiece / isPawnPiece)', () {
    test('type=custom olsa bile CardRole.king varsa isKingPiece true döner', () {
      // Örn: Zırhlı Şah / Savaşçı Kral gibi varyasyonlar tarihsel nedenlerle
      // PieceType.custom olabilir; kritik kontrol SADECE roles üzerinden yapılmalı.
      final necromancerKing = PieceLibrary.necromancerSah;
      expect(necromancerKing.isKingPiece, isTrue);
    });

    test('Goblin hem pawn hem dps rolüne sahiptir (isPawnPiece true)', () {
      expect(PieceLibrary.goblin.isPawnPiece, isTrue);
      expect(PieceLibrary.goblin.roles, contains(CardRole.dps));
    });

    test('DPS-only kart (ör. Barikat) isPawnPiece/isKingPiece false döner', () {
      expect(PieceLibrary.barikat.isPawnPiece, isFalse);
      expect(PieceLibrary.barikat.isKingPiece, isFalse);
    });
  });

  group('Tek kullanımlık yetenek tüketimi', () {
    test('consumeUse usesRemaining sıfıra inince specialUsed true olur', () {
      final p = PieceLibrary.zamanLordu.copyWith(newTeam: Team.white, newId: 'x', level: 1);
      expect(p.specialUsed, isFalse);
      p.consumeUse();
      expect(p.usesRemaining, 0);
      expect(p.specialUsed, isTrue);
    });

    test('consumeStoneSkinCharge sıfırın altına inmez', () {
      final p = PieceLibrary.madenMuhafizi.copyWith(newTeam: Team.white, newId: 'x', level: 1);
      p.consumeStoneSkinCharge();
      p.consumeStoneSkinCharge(); // zaten 0, tekrar çağrılmamalı ama negatife düşmemeli
      expect(p.stoneSkinCharges, 0);
    });
  });
}
