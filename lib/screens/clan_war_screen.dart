import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/piece_library.dart';
import '../models/formation_service.dart';
import '../models/clan_service.dart';
import '../controllers/board_controller.dart';
import '../widgets/board_grid.dart';

/// Klan Savaşı: oyuncunun "Kartlarım > Diziliş" ekranında seçtiği dizilimle,
/// güçlü, sabit bir "rakip klan şampiyonu" dizilimine karşı oynanan tek
/// seferlik bir maç. Sonuç [ClanService]'e bildirilir (skor + görevler).
class ClanWarScreen extends StatefulWidget {
  const ClanWarScreen({Key? key}) : super(key: key);

  @override
  State<ClanWarScreen> createState() => _ClanWarScreenState();
}

class _ClanWarScreenState extends State<ClanWarScreen> {
  final BoardController controller = BoardController();
  int? selectedRow;
  int? selectedCol;
  List<Point> highlightedMoves = [];
  bool resultRecorded = false;

  @override
  void initState() {
    super.initState();
    _startBattle();
  }

  void _startBattle() {
    FormationService.instance.sanitize();
    final formation = FormationService.instance;

    controller.initBoard(
      whitePawns: formation.pawns,
      whiteDpsLeft: formation.dpsLeft,
      whiteDpsRight: formation.dpsRight,
      whiteQueen: formation.queen,
      whiteKing: formation.king,
      // Rakip klan şampiyonu: güçlü, sabit bir "boss" dizilimi.
      blackPawns: List.filled(BoardController.cols, PieceLibrary.pawn),
      blackDpsLeft: PieceLibrary.barikat,
      blackDpsRight: PieceLibrary.kabus,
      blackQueen: PieceLibrary.darkEnchantress,
      blackKing: PieceLibrary.armoredKing,
    );
    selectedRow = null;
    selectedCol = null;
    highlightedMoves = [];
    resultRecorded = false;
  }

  void _onSquareTap(int row, int col) {
    setState(() {
      if (selectedRow == null && selectedCol == null) {
        final piece = controller.grid[row][col];
        if (piece != null && piece.team == controller.currentTurn) {
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

        if (controller.winner != null && !resultRecorded) {
          resultRecorded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _showResultDialog());
        }
      }
    });
  }

  void _showResultDialog() {
    final won = controller.winner == Team.white;
    ClanService.instance.recordWarBattleResult(won);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc('clan_war_title')),
        content: Text(won ? loc('clan_war_result_won') : loc('clan_war_result_lost')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(); // savaş ekranı -> klan paneline dön
            },
            child: Text(loc('clan_war_return')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        final isCheck = controller.lastMoveWasCheck && controller.winner == null;
        final turnLabel =
            controller.currentTurn == Team.white ? loc('turn_white') : loc('turn_black');
        final turnColor = controller.currentTurn == Team.white ? Colors.white : Colors.black87;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(ClanService.rivalClanIcon),
                const SizedBox(width: 8),
                Text('${loc('clan_war_title')} · ${ClanService.rivalClanName}'),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: turnColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(turnLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isCheck) ...[
                        const SizedBox(width: 12),
                        Text(
                          loc('check'),
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 8),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
