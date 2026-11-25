import 'piece_base.dart';

/// ♘ At — Ücretsiz başlangıç kartı. Klasik "L" şeklinde sıçrama.
final Piece knightBasicPiece = Piece(
  id: 'knight_basic',
  nameKey: 'piece_knight_basic',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.knightStyle,
  emoji: '♘',
  hp: 2,
  maxHp: 2,
  attackPower: 1,
  rarity: Rarity.common,
  roles: const [CardRole.dps],
);
