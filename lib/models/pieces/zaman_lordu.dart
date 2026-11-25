import 'piece_base.dart';

/// ⏳ Zaman Lordu — Geri Sarma: oyunda bir kez, rakibin son hamlesini
/// iptal edip tahtayı o hamleden önceki haline döndürür; sıra yine
/// senin takımında kalır (ekstra hamle).
/// TEST İPUCU: Önce herhangi bir taşı (rakip dahil) hareket ettir,
/// sonra Zaman Lordu'nu seç; ekranda "Geri Sar" butonu belirecek.
final Piece zamanLorduPiece = Piece(
  id: 'zaman_lordu',
  nameKey: 'piece_zaman_lordu',
  type: PieceType.queen,
  team: Team.white,
  moveStyle: MoveStyle.queenStyle,
  emoji: '⏳',
  hp: 2,
  maxHp: 2,
  attackPower: 2,
  rarity: Rarity.mythic,
  roles: const [CardRole.queen],
  ability: SpecialAbility.rewind,
);
