import 'piece_base.dart';

/// 🦄 Pegasus — Rüzgar Süzülüşü: At tarzı hamlesini tamamladığında,
/// indiği karenin çevresindeki (1 kare) dost PİYONLARA 1 hamlelik
/// kalkan (bir sonraki hasarı tamamen söndürür) verir.
/// TEST İPUCU: Bir sıçrama yap, iniş karesinin komşusundaki dost piyona
/// uzun bas; 🛡️ ikonunu ve "kalkanlı" durumunu göreceksin.
final Piece pegasusPiece = Piece(
  id: 'pegasus',
  nameKey: 'piece_pegasus',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.knightStyle,
  emoji: '🦄',
  hp: 2,
  maxHp: 2,
  attackPower: 1,
  rarity: Rarity.rare,
  roles: const [CardRole.dps],
  ability: SpecialAbility.windGlideShield,
);
