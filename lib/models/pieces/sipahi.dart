import 'piece_base.dart';

/// 🐎 Sipahi — Süvari Hücumu: ilk hamlesinde 3 kare düz ileri atlayabilir.
/// TEST İPUCU: Beyaz başlangıç sırasında (satır 6) dururken hareket
/// listesine bak; 1, 2 VE 3 kare ileri seçenekleri görünmeli.
final Piece sipahiPiece = Piece(
  id: 'sipahi',
  nameKey: 'piece_sipahi',
  type: PieceType.pawn,
  team: Team.white,
  moveStyle: MoveStyle.pawnStyle,
  emoji: '🐎',
  hp: 1,
  maxHp: 1,
  attackPower: 1,
  rarity: Rarity.common,
  roles: const [CardRole.pawn],
  ability: SpecialAbility.cavalryRush,
);
