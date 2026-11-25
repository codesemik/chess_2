import 'piece_base.dart';

/// 🧙‍♀️ Kara Büyücü — Yetenek yok. Vezir tarzı hareket eder, yüksek
/// saldırı gücüne sahiptir.
final Piece darkEnchantressPiece = Piece(
  id: 'dark_enchantress',
  nameKey: 'piece_dark_enchantress',
  type: PieceType.queen,
  team: Team.white,
  moveStyle: MoveStyle.queenStyle,
  emoji: '🧙‍♀️',
  hp: 2,
  maxHp: 2,
  attackPower: 3,
  rarity: Rarity.epic,
  roles: const [CardRole.queen],
);
