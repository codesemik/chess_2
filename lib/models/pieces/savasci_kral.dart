import 'piece_base.dart';

/// ⚔️ Savaşçı Kral — Son Direniş: şah çekildiğinde, bitişikteki tehdit
/// eden taşı yiyerek şah durumundan çıkabilir.
/// NOT: Bu motorda Şah zaten her zaman bitişik bir rakibi normal
/// hareketiyle yiyebiliyor; bu kart o davranışı temalandırır, ek bir
/// kod gerektirmez.
/// TEST İPUCU: Bitişiğindeki rakip taşı seçip (Şahı seç, o kareye dokun)
/// doğrudan yiyebildiğini gör.
final Piece savasciKralPiece = Piece(
  id: 'savasci_kral',
  nameKey: 'piece_savasci_kral',
  type: PieceType.king,
  team: Team.white,
  moveStyle: MoveStyle.kingStyle,
  emoji: '⚔️',
  hp: 4,
  maxHp: 4,
  attackPower: 2,
  rarity: Rarity.epic,
  roles: const [CardRole.king],
  ability: SpecialAbility.lastStand,
);
