import 'piece_base.dart';

/// 🐉 Ejderha Kraliçe — Alev Hattı: Vezir tarzı bir vuruşla düşman
/// elendiğinde, geldiği doğrultuda hedefin bir kare arkasını 1 tur
/// boyunca ateşe verir; o kareye kimse giremez.
/// TEST İPUCU: Düz bir hatta bir düşmanı vur; vurduğun karenin bir
/// ötesinde 🔥 ikonu beliriyor mu kontrol et.
final Piece ejderhaKralicePiece = Piece(
  id: 'ejderha_kralice',
  nameKey: 'piece_ejderha_kralice',
  type: PieceType.queen,
  team: Team.white,
  moveStyle: MoveStyle.queenStyle,
  emoji: '🐉',
  hp: 3,
  maxHp: 3,
  attackPower: 3,
  rarity: Rarity.legendary,
  roles: const [CardRole.queen],
  ability: SpecialAbility.flameLine,
);
