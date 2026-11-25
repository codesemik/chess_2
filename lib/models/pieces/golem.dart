import 'piece_base.dart';

/// 🗿 Kaya Golem — Yetenek yok. Kale tarzı düz sınırsız hareket eder,
/// yüksek canlı bir tank.
final Piece golemPiece = Piece(
  id: 'golem',
  nameKey: 'piece_golem',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.rookStyle,
  emoji: '🗿',
  hp: 4,
  maxHp: 4,
  attackPower: 1,
  rarity: Rarity.epic,
  roles: const [CardRole.dps],
);
