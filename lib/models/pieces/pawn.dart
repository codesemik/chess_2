import 'piece_base.dart';

/// ♙ Piyon — Ücretsiz başlangıç kartı. Standart satranç piyonu:
/// ileri gider, çapraz vurur, ilk hamlede 2 kare gidebilir.
final Piece pawnBasicPiece = Piece(
  id: 'pawn_basic',
  nameKey: 'piece_pawn',
  type: PieceType.pawn,
  team: Team.white,
  moveStyle: MoveStyle.pawnStyle,
  emoji: '♙',
  hp: 1,
  maxHp: 1,
  attackPower: 1,
  rarity: Rarity.common,
  roles: const [CardRole.pawn],
);
