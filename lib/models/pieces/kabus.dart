import 'piece_base.dart';

/// 👹 Kabus (Nightmare) — Korku Halesi: At tarzı hamlesini tamamladığında,
/// indiği karenin komşularındaki rakip piyon/kale/fil tarzı taşları
/// 1 tur boyunca kilitler (hareket edemezler).
/// TEST İPUCU: Bir sıçrama yap, iniş karesinin komşusundaki rakibe
/// uzun bas; ❄️ ikonunu göreceksin — o taşı seçtiğinde hiç hareket
/// seçeneği çıkmayacak.
final Piece kabusPiece = Piece(
  id: 'kabus',
  nameKey: 'piece_kabus',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.knightStyle,
  emoji: '👹',
  hp: 2,
  maxHp: 2,
  attackPower: 2,
  rarity: Rarity.legendary,
  roles: const [CardRole.dps],
  ability: SpecialAbility.fearAura,
);
