import 'piece_base.dart';

/// ♔ Şah — Ücretsiz başlangıç kartı. Her yöne 1 kare hareket eder.
/// Canı biterse oyun biter.
final Piece kingBasicPiece = Piece(
  id: 'king_basic',
  nameKey: 'piece_king',
  type: PieceType.king,
  team: Team.white,
  moveStyle: MoveStyle.kingStyle,
  emoji: '♔',
  hp: 3,
  maxHp: 3,
  attackPower: 1,
  rarity: Rarity.common,
  roles: const [CardRole.king],
);
