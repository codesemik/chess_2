import 'piece_base.dart';

/// 👺 Goblin — Yetenek yok. At tarzı ("L") sıçrar. Hem piyon sırasına
/// hem DPS slotuna yerleştirilebilen tek karttır.
final Piece goblinPiece = Piece(
  id: 'goblin',
  nameKey: 'piece_goblin',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.knightStyle,
  emoji: '👺',
  hp: 2,
  maxHp: 2,
  attackPower: 1,
  rarity: Rarity.common,
  roles: const [CardRole.pawn, CardRole.dps],
);
