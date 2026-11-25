import 'piece_base.dart';

/// 🥷 Gölge Piyonu — Kör Nokta: önündeki taşın (dost/düşman/boş fark
/// etmeksizin) üzerinden aşıp 2 kare çaprazdaki bir düşmanı vurabilir.
/// TEST İPUCU: Sağ-çaprazında bir dost, onun 1 kare ötesinde bir düşman
/// varken hareket listesine bak; düşmanı hedefleyen kırmızı nokta görünmeli.
final Piece golgePiyonuPiece = Piece(
  id: 'golge_piyonu',
  nameKey: 'piece_golge_piyonu',
  type: PieceType.pawn,
  team: Team.white,
  moveStyle: MoveStyle.pawnStyle,
  emoji: '🥷',
  hp: 1,
  maxHp: 1,
  attackPower: 2,
  rarity: Rarity.legendary,
  roles: const [CardRole.pawn],
  ability: SpecialAbility.blindSpotStrike,
);
