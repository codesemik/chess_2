import '../controllers/board_controller.dart';
import 'piece_library.dart';

/// Bir kartın Kart Test Odası'nda nasıl kurulacağını tanımlar: hangi
/// taşların tahtanın neresine konacağı ve (varsa) önceden ayarlanması
/// gereken durum (ör. Şaman için "1 ölü piyon var" sayılması).
/// KURAL: listedeki İLK yerleşim her zaman test edilen "yıldız" taştır;
/// seviye seçici sadece onu etkiler, diğer figüranlar her zaman seviye 1'dir.
class PieceTestScenario {
  final List<ScenarioPlacement> placements;
  final Map<Team, int>? presetDeadPawns;
  const PieceTestScenario(this.placements, {this.presetDeadPawns});

  /// Bu senaryoyu, yıldız taş (ilk yerleşim) verilen seviyede olacak
  /// şekilde yeniden oluşturur. Diğer tüm figüranlar etkilenmez.
  PieceTestScenario withStarLevel(int level) {
    if (placements.isEmpty) return this;
    final star = placements.first;
    final rest = placements.skip(1);
    return PieceTestScenario(
      [
        ScenarioPlacement(star.piece, star.team, star.row, star.col, level: level),
        ...rest,
      ],
      presetDeadPawns: presetDeadPawns,
    );
  }
}

/// Özel yeteneği olan kartlar için ELLE hazırlanmış, yeteneği net bir
/// şekilde gösteren senaryolar. Diğer tüm kartlar (yeteneksiz olanlar)
/// [genericScenarioFor] ile otomatik oluşturulan basit bir senaryo alır.
final Map<String, PieceTestScenario> _curatedScenarios = {
  // --- Piyon varyasyonları ---
  PieceLibrary.sipahi.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.sipahi, Team.white, 6, 1),
  ]),
  PieceLibrary.madenMuhafizi.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.madenMuhafizi, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.golem, Team.black, 4, 3),
  ]),
  PieceLibrary.golgePiyonu.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.golgePiyonu, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.white, 3, 2),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 2, 3),
  ]),

  // --- At varyasyonları ---
  PieceLibrary.pegasus.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.pegasus, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.white, 1, 0),
  ]),
  PieceLibrary.kabus.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.kabus, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 1, 0),
  ]),

  // --- Fil varyasyonları ---
  PieceLibrary.buyucu.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.buyucu, Team.white, 4, 1),
  ]),
  PieceLibrary.saman.id: PieceTestScenario(
    [
      ScenarioPlacement(PieceLibrary.saman, Team.white, 4, 1),
      ScenarioPlacement(PieceLibrary.pawn, Team.black, 0, 3),
    ],
    presetDeadPawns: {Team.white: 1},
  ),

  // --- Kale varyasyonları ---
  PieceLibrary.mancinik.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.mancinik, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 2, 1), // engel (görmezden gelinir)
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 1, 1), // 3 kare yukarı hedef
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 7, 1), // 3 kare aşağı hedef
  ]),
  PieceLibrary.barikat.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.barikat, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.white, 4, 0), // korunan dost
    ScenarioPlacement(PieceLibrary.knightBasic, Team.black, 2, 1), // (4,0)'a sıçrayabilirdi
  ]),

  // --- Vezir varyasyonları ---
  PieceLibrary.ejderhaKralice.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.ejderhaKralice, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 1, 1),
  ]),
  PieceLibrary.zamanLordu.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.zamanLordu, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 6, 2),
  ]),

  // --- Şah varyasyonları ---
  PieceLibrary.savasciKral.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.savasciKral, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 4, 2),
  ]),
  PieceLibrary.necromancerSah.id: PieceTestScenario([
    ScenarioPlacement(PieceLibrary.necromancerSah, Team.white, 4, 1),
  ]),
};

/// Özel bir senaryosu olmayan (yeteneksiz) kartlar için otomatik, genel
/// bir test kurulumu: taş ortada, etrafında birkaç rakip piyon —
/// hareket desenini görmek için yeterli.
PieceTestScenario _genericScenarioFor(Piece piece) {
  return PieceTestScenario([
    ScenarioPlacement(piece, Team.white, 4, 1),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 4, 3),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 1, 0),
    ScenarioPlacement(PieceLibrary.pawn, Team.black, 3, 1),
  ]);
}

/// Verilen kart için test senaryosunu döndürür (elle hazırlanmış varsa
/// onu, yoksa otomatik genel senaryoyu).
PieceTestScenario scenarioFor(Piece piece) =>
    _curatedScenarios[piece.id] ?? _genericScenarioFor(piece);
