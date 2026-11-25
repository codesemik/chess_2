import 'piece_base.dart';

/// 🔮 Büyücü (İllüzyonist) — Ayna Yansıması: oyunda bir kez, dik/yatay
/// 1 kare kayarak kare rengini değiştirebilir (normal Fil hareketinden
/// farklı olarak köşegen DEĞİL, ortogonal bir kayma).
/// TEST İPUCU: Taşı seç; normal çapraz hareketlerin yanında dik/yatay
/// bitişik karelerde de yeşil nokta göreceksin. Onu kullandıktan sonra
/// yetenek ikonu grileşir ve bir daha çıkmaz.
final Piece buyucuPiece = Piece(
  id: 'buyucu',
  nameKey: 'piece_buyucu',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.bishopStyle,
  emoji: '🔮',
  hp: 1,
  maxHp: 1,
  attackPower: 2,
  rarity: Rarity.rare,
  roles: const [CardRole.dps],
  ability: SpecialAbility.mirrorReflection,
);
