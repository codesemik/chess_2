import 'piece_base.dart';

/// 🏹 Okçu İskelet — Yetenek yok. Fil tarzı çapraz sınırsız hareket eder.
final Piece skeleArcherPiece = Piece(
  id: 'skele_archer',
  nameKey: 'piece_skele_archer',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.bishopStyle,
  emoji: '🏹',
  hp: 1,
  maxHp: 1,
  attackPower: 2,
  rarity: Rarity.rare,
  roles: const [CardRole.dps],
);
