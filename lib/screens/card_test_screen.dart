import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/piece_library.dart';
import '../models/piece_test_scenarios.dart';
import '../models/card_level_service.dart';
import '../controllers/board_controller.dart';
import '../utils/rarity_utils.dart';
import '../widgets/board_grid.dart';

/// Kart Test Odası: her kartı TEK TEK, izole bir senaryoda deneyebileceğin
/// bir sandbox. Sıra/takım kısıtlaması yoktur — istediğin taşı, istediğin
/// zaman, istediğin kadar oynatabilirsin. Her kart seçildiğinde, o kartın
/// yeteneğini net biçimde gösteren özel bir tahta düzeni yüklenir.
class CardTestScreen extends StatefulWidget {
  const CardTestScreen({Key? key}) : super(key: key);

  @override
  State<CardTestScreen> createState() => _CardTestScreenState();
}

class _CardTestScreenState extends State<CardTestScreen> {
  final BoardController controller = BoardController();
  late Piece selectedPiece;
  int selectedLevel = 1;

  int? selectedRow;
  int? selectedCol;
  List<Point> highlightedMoves = [];

  @override
  void initState() {
    super.initState();
    selectedPiece = PieceLibrary.sipahi;
    _loadScenario(selectedPiece);
  }

  void _loadScenario(Piece piece) {
    final scenario = scenarioFor(piece).withStarLevel(selectedLevel);
    controller.loadScenario(scenario.placements, presetDeadPawns: scenario.presetDeadPawns);
    selectedRow = null;
    selectedCol = null;
    highlightedMoves = [];
  }

  void _selectPiece(Piece piece) {
    setState(() {
      selectedPiece = piece;
      selectedLevel = 1;
      _loadScenario(piece);
    });
  }

  void _selectLevel(int level) {
    setState(() {
      selectedLevel = level;
      _loadScenario(selectedPiece);
    });
  }

  void _resetScenario() {
    setState(() => _loadScenario(selectedPiece));
  }

  void _onSquareTap(int row, int col) {
    setState(() {
      if (selectedRow == null && selectedCol == null) {
        final piece = controller.grid[row][col];
        if (piece != null) {
          selectedRow = row;
          selectedCol = col;
          highlightedMoves = controller.legalMovesFor(row, col);
        }
      } else {
        final isLegal = highlightedMoves.contains(Point(row, col));
        if (isLegal) {
          controller.movePiece(selectedRow!, selectedCol!, row, col);
        }
        selectedRow = null;
        selectedCol = null;
        highlightedMoves = [];
      }
    });
  }

  void _tryRewind() {
    if (selectedRow == null || selectedCol == null) return;
    final piece = controller.grid[selectedRow!][selectedCol!];
    if (piece == null) return;
    setState(() {
      controller.rewind(piece);
      selectedRow = null;
      selectedCol = null;
      highlightedMoves = [];
    });
  }

  void _openPiecePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final sections = <MapEntry<String, List<Piece>>>[
          MapEntry(loc('tab_collection'), PieceLibrary.starterCards),
          MapEntry(loc('tier_pawn'), PieceLibrary.pawnTierStoreItems),
          MapEntry(loc('tier_knight'), PieceLibrary.knightTierStoreItems),
          MapEntry(loc('tier_bishop'), PieceLibrary.bishopTierStoreItems),
          MapEntry(loc('tier_rook'), PieceLibrary.rookTierStoreItems),
          MapEntry(loc('tier_queen'), PieceLibrary.queenTierStoreItems),
          MapEntry(loc('tier_king'), PieceLibrary.kingTierStoreItems),
        ];
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                    child: Text(
                      section.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: section.value.map((piece) {
                      final isSelected = piece.id == selectedPiece.id;
                      final color = rarityColor(piece.rarity);
                      return GestureDetector(
                        onTap: () {
                          _selectPiece(piece);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 84,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.greenAccent : color,
                              width: 2,
                            ),
                            color: isSelected
                                ? Colors.greenAccent.withOpacity(0.15)
                                : color.withOpacity(0.1),
                          ),
                          child: Column(
                            children: [
                              Text(piece.emoji, style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(
                                piece.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              if (piece.hasSpecialAbility) ...[
                                const SizedBox(height: 2),
                                const Icon(Icons.auto_awesome, size: 12, color: Colors.amberAccent),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        final selectedBoardPiece = (selectedRow != null && selectedCol != null)
            ? controller.grid[selectedRow!][selectedCol!]
            : null;
        final canRewind = selectedBoardPiece != null &&
            selectedBoardPiece.ability == SpecialAbility.rewind &&
            !selectedBoardPiece.specialUsed &&
            controller.hasHistory;

        return Scaffold(
          appBar: AppBar(title: Text(loc('test_lab_title'))),
          body: SafeArea(
            child: Column(
              children: [
                // --- Kart seçici ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _openPiecePicker,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: rarityColor(selectedPiece.rarity), width: 2),
                        color: rarityColor(selectedPiece.rarity).withOpacity(0.08),
                      ),
                      child: Row(
                        children: [
                          Text(selectedPiece.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedPiece.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  rarityLabel(selectedPiece.rarity),
                                  style: TextStyle(fontSize: 11, color: rarityColor(selectedPiece.rarity)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.swap_horiz),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Seviye seçici ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Text('${loc('level')}: ', style: const TextStyle(fontSize: 12)),
                      ...List.generate(CardLevelService.maxLevel, (i) {
                        final level = i + 1;
                        final isSelected = level == selectedLevel;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('Lv.$level'),
                            selected: isSelected,
                            onSelected: (_) => _selectLevel(level),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // --- Yetenek açıklaması (seçilen seviyeye göre önizleme) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Builder(builder: (context) {
                    final preview = selectedPiece.copyWith(level: selectedLevel);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                            Text(' ${preview.maxHp}   ', style: const TextStyle(fontSize: 11)),
                            const Icon(Icons.bolt, size: 12, color: Colors.orangeAccent),
                            Text(' ${preview.attackPower}', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(selectedPiece.moveDescription, style: const TextStyle(fontSize: 12)),
                        if (selectedPiece.hasSpecialAbility) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.auto_awesome, size: 14, color: Colors.amberAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  preview.abilityDescription,
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  }),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetScenario,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(loc('test_reset')),
                      ),
                      if (canRewind)
                        ElevatedButton.icon(
                          onPressed: _tryRewind,
                          icon: const Icon(Icons.replay, size: 16),
                          label: Text(loc('rewind_button')),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 16),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BoardGrid(
                        controller: controller,
                        selectedRow: selectedRow,
                        selectedCol: selectedCol,
                        highlightedMoves: highlightedMoves,
                        onSquareTap: _onSquareTap,
                        onPieceLongPress: (piece) => showPieceInfoDialog(context, piece),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    loc('test_lab_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
