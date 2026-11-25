import 'piece_base.dart';

/// ♖ Kale — Ücretsiz başlangıç kartı. Düz sınırsız hareket eder.
final Piece rookBasicPiece = Piece(
  id: 'rook_basic',
  nameKey: 'piece_rook_basic',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.rookStyle,
  emoji: '♖',
  hp: 3,
  maxHp: 3,
  attackPower: 1,
  rarity: Rarity.common,
  roles: const [CardRole.dps],
);
