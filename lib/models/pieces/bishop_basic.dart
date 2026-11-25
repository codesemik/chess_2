import 'piece_base.dart';

/// ♗ Fil — Ücretsiz başlangıç kartı. Çapraz sınırsız hareket eder.
final Piece bishopBasicPiece = Piece(
  id: 'bishop_basic',
  nameKey: 'piece_bishop_basic',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.bishopStyle,
  emoji: '♗',
  hp: 1,
  maxHp: 1,
  attackPower: 2,
  rarity: Rarity.common,
  roles: const [CardRole.dps],
);
