import 'piece_base.dart';

/// ♕ Vezir — Ücretsiz başlangıç kartı. Düz + çapraz sınırsız hareket eder.
final Piece queenBasicPiece = Piece(
  id: 'queen_basic',
  nameKey: 'piece_queen',
  type: PieceType.queen,
  team: Team.white,
  moveStyle: MoveStyle.queenStyle,
  emoji: '♕',
  hp: 2,
  maxHp: 2,
  attackPower: 2,
  rarity: Rarity.common,
  roles: const [CardRole.queen],
);
