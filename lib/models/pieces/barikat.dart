import 'piece_base.dart';

/// 🧱 Barikat Kalesi — Ağır Taş: bitişiğindeki (dik/yatay 1 kare) dost
/// taşlar rakip atların sıçrama saldırılarından korunur.
/// TEST İPUCU: Barikat'ın bitişiğindeki dost piyonu, rakip Atı seçip
/// vurmaya çalış — o kareye yönelik saldırı seçeneği ÇIKMAYACAK.
final Piece barikatPiece = Piece(
  id: 'barikat',
  nameKey: 'piece_barikat',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.rookStyle,
  emoji: '🧱',
  hp: 5,
  maxHp: 5,
  attackPower: 1,
  rarity: Rarity.epic,
  roles: const [CardRole.dps],
  ability: SpecialAbility.barricade,
);
