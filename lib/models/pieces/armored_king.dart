import 'piece_base.dart';

/// 🛡️ Zırhlı Şah — Yetenek yok. Şah tarzı hareket eder, çok yüksek canı
/// olan bir tank-şah.
final Piece armoredKingPiece = Piece(
  id: 'armored_king',
  nameKey: 'piece_armored_king',
  type: PieceType.king,
  team: Team.white,
  moveStyle: MoveStyle.kingStyle,
  emoji: '🛡️',
  hp: 5,
  maxHp: 5,
  attackPower: 1,
  rarity: Rarity.rare,
  roles: const [CardRole.king],
);
