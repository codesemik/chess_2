import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/localization_service.dart';
import '../models/piece_library.dart';
import '../models/profile_service.dart';
import '../models/formation_service.dart';
import '../models/collection_service.dart';
import '../models/card_level_service.dart';
import '../models/auth_service.dart';
import '../models/matchmaking_service.dart';
import '../models/online_match_controller.dart';
import '../controllers/board_controller.dart';
import '../utils/rarity_utils.dart';
import '../widgets/board_grid.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

enum _PlayState { lobby, searching, playing }

/// "Oyun" sekmesi: Bir lobi (sol üstte profil, sağ üstte ayarlar, ortada
/// Savaş butonu), gerçek bir rakip aranan bekleme ekranı ve GERÇEK bir
/// oyuncuya karşı canlı oynanan 4x8 satranç tahtasından oluşur. Dizilim
/// burada değiştirilemez; sadece "Kartlarım > Diziliş" ekranında seçilmiş
/// kartlar maça taşınır.
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _PlayState playState = _PlayState.lobby;
  OnlineMatchController? _match;
  bool _resultHandled = false;
  bool _showWaitingHint = false;
  String? _resumableMatchId;
  Timer? _uiTickTimer;

  int? selectedRow;
  int? selectedCol;
  List<Point> highlightedMoves = [];

  @override
  void initState() {
    super.initState();
    _checkForActiveMatch();
  }

  @override
  void dispose() {
    _uiTickTimer?.cancel();
    _match?.dispose();
    MatchmakingService.instance.cancel();
    super.dispose();
  }

  /// Uygulama kapatılıp açıldığında ya da sekme değiştirildiğinde, hâlâ
  /// bitmemiş bir maçın varsa (yarım kalmış bir bağlantı yüzünden) lobiye
  /// bir "devam et" seçeneği ekler.
  Future<void> _checkForActiveMatch() async {
    final uid = AuthService.instance.uid;
    if (uid == null) return;
    try {
      final matchesCol = FirebaseFirestore.instance.collection('matches');
      final asWhite = await matchesCol
          .where('whiteUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      final asBlack = await matchesCol
          .where('blackUid', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      final found = asWhite.docs.isNotEmpty
          ? asWhite.docs.first.id
          : (asBlack.docs.isNotEmpty ? asBlack.docs.first.id : null);
      if (found != null && mounted) {
        setState(() => _resumableMatchId = found);
      }
    } catch (e) {
      debugPrint('GameScreen: devam eden maç kontrolü başarısız: $e');
    }
  }

  void _resumeMatch(String matchId) {
    setState(() => _resumableMatchId = null);
    _onMatched(matchId);
  }

  void _startSearching() {
    setState(() {
      playState = _PlayState.searching;
      _showWaitingHint = false;
    });
    // 8 saniye sonra hâlâ arıyorsak, kullanıcıyı bilgilendir: bu normaldir
    // (henüz uygun bir rakip bulunamamış olabilir), bir hata değildir.
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && playState == _PlayState.searching) {
        setState(() => _showWaitingHint = true);
      }
    });
    MatchmakingService.instance.findMatch(
      onMatched: _onMatched,
      onError: (e) {
        if (!mounted) return;
        setState(() => playState = _PlayState.lobby);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc('searching_error'))),
        );
      },
    );
  }

  void _onMatched(String matchId) {
    if (!mounted) return;
    final match = OnlineMatchController(matchId);
    match.listen(() {
      if (!mounted) return;
      setState(() {
        if (match.controller.winner != null && !_resultHandled) {
          _resultHandled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOverDialog());
        }
      });
    });
    _uiTickTimer?.cancel();
    // Rakibin "bağlantısı kopmuş olabilir" durumu ZAMANA bağlıdır, yeni bir
    // Firestore verisi gelmeden de değişebilir — bu yüzden periyodik olarak
    // ekranı tazeliyoruz (sadece bu sayaç göstergesi için).
    _uiTickTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && playState == _PlayState.playing) setState(() {});
    });
    setState(() {
      _match = match;
      playState = _PlayState.playing;
      selectedRow = null;
      selectedCol = null;
      highlightedMoves = [];
      _resultHandled = false;
    });
  }

  void _cancelSearching() {
    MatchmakingService.instance.cancel();
    setState(() => playState = _PlayState.lobby);
  }

  void _returnToLobby() {
    _uiTickTimer?.cancel();
    _match?.dispose();
    setState(() {
      _match = null;
      playState = _PlayState.lobby;
    });
  }

  /// Tahtadaki geri okuna basılınca çağrılır. Maç hâlâ devam ediyorsa
  /// (kazanan belli değilse) sessizce çıkmak yerine pes etme onayı ister
  /// — yoksa maç ortada asılı kalır ve rakip sonsuza dek bekler.
  Future<void> _confirmLeaveMatch() async {
    final match = _match;
    if (match == null || match.controller.winner != null) {
      _returnToLobby();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc('leave_match_title')),
        content: Text(loc('leave_match_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc('close')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(loc('resign_button')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await match.resign();
      _returnToLobby();
    }
  }

  Future<void> _onSquareTap(int row, int col) async {
    final match = _match;
    if (match == null) return;
    final controller = match.controller;

    if (selectedRow == null && selectedCol == null) {
      final piece = controller.grid[row][col];
      if (piece != null && piece.team == controller.currentTurn && match.isMyTurn) {
        setState(() {
          selectedRow = row;
          selectedCol = col;
          highlightedMoves = controller.legalMovesFor(row, col);
        });
      } else if (piece != null) {
        debugPrint(
            'GameScreen: taş seçilemedi (piece.team=${piece.team}, '
            'currentTurn=${controller.currentTurn}, isMyTurn=${match.isMyTurn}, '
            'myColor=${match.myColor})');
      }
      return;
    }

    final isLegal = highlightedMoves.contains(Point(row, col));
    final fromRow = selectedRow!;
    final fromCol = selectedCol!;
    setState(() {
      selectedRow = null;
      selectedCol = null;
      highlightedMoves = [];
    });
    if (isLegal) {
      await match.tryMove(fromRow, fromCol, row, col);
      // Not: sonuç ekranı ve tahta güncellemesi `OnlineMatchController.listen`
      // callback'i üzerinden (Firestore'un bize kendi yazdığımızı da geri
      // yansıtmasıyla) otomatik gelir; burada ayrıca setState gerekmez.
    }
  }

  void _showPieceInfo(Piece piece) => showPieceInfoDialog(context, piece);

  Future<void> _tryRewind() async {
    final match = _match;
    if (match == null || selectedRow == null || selectedCol == null) return;
    final piece = match.controller.grid[selectedRow!][selectedCol!];
    if (piece == null) return;
    setState(() {
      selectedRow = null;
      selectedCol = null;
      highlightedMoves = [];
    });
    await match.tryRewind(piece);
  }

  Future<void> _resign() async {
    final match = _match;
    if (match == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc('resign_confirm_title')),
        content: Text(loc('resign_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc('close')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(loc('resign_button')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await match.resign();
    }
  }

  void _showGameOverDialog() {
    final match = _match;
    if (match == null) return;
    final winner = match.controller.winner;
    if (winner == null) return;
    final iWon = winner == match.myColor;

    // Kupa ödülü: kazanınca +20, kaybedince -10 (0'ın altına inmez).
    ProfileService.instance.addTrophies(iWon ? 20 : -10);

    final String message;
    switch (match.endReason) {
      case 'resigned':
        message = iWon ? loc('match_opponent_resigned') : loc('match_you_resigned');
        break;
      case 'opponent_disconnected':
        message = iWon ? loc('match_won_by_disconnect') : loc('match_lost_by_disconnect');
        break;
      default:
        message = iWon ? loc('match_you_won') : loc('match_you_lost');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc('game_over')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _returnToLobby();
            },
            child: Text(loc('return_to_lobby')),
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
        switch (playState) {
          case _PlayState.lobby:
            return _buildLobby();
          case _PlayState.searching:
            return _buildSearching();
          case _PlayState.playing:
            return _buildBoard();
        }
      },
    );
  }

  // ---------------------------------------------------------------------
  // LOBİ
  // ---------------------------------------------------------------------

  Widget _buildLobby() {
    // Stack + Positioned yerine düz bir Column kullanılır: bu sayede üst
    // satırdaki Profil/Ayarlar butonları küçük ekranlarda ortadaki içerikle
    // asla çakışmaz (Stack ile mutlak konumlandırmanın önceki sorunu buydu).
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProfileButton(),
              Row(
                children: [
                  _buildGoldChip(),
                  _buildSettingsButton(),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc('app_title'),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc('lobby_subtitle'),
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  if (_resumableMatchId != null) ...[
                    _buildResumeMatchCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildFormationPreview(),
                  const SizedBox(height: 32),
                  _buildBattleButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Yarım kalmış (aktif ama terk edilmiş) bir maçın varsa, ona geri
  /// dönmen için bir kart gösterir.
  Widget _buildResumeMatchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.amberAccent.withOpacity(0.1),
        border: Border.all(color: Colors.amberAccent),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              Text(loc('resume_match_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _resumeMatch(_resumableMatchId!),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
            child: Text(loc('resume_match_button'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  /// Oyuncunun "Kartlarım > Diziliş"te seçtiği takımın küçük bir önizlemesi:
  /// tahtadaki gerçek düzenle aynı sırada (DPS-Sol, Şah, Vezir, DPS-Sağ)
  /// gösterilir; her kartın seviyesi de rozetle görünür.
  Widget _buildFormationPreview() {
    return ListenableBuilder(
      listenable: Listenable.merge([FormationService.instance, CardLevelService.instance]),
      builder: (context, _) {
        FormationService.instance.sanitize();
        final formation = FormationService.instance;
        final slots = [
          formation.dpsLeft,
          formation.king,
          formation.queen,
          formation.dpsRight,
        ];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: slots.map((piece) {
              final level = CardLevelService.instance.levelOf(piece.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: rarityColor(piece.rarity).withOpacity(0.2),
                          child: Text(piece.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        if (level > 1)
                          Positioned(
                            bottom: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: rarityColor(piece.rarity)),
                              ),
                              child: Text('Lv.$level', style: const TextStyle(fontSize: 8)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 56,
                      child: Text(
                        piece.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildGoldChip() {
    return ListenableBuilder(
      listenable: CollectionService.instance,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Chip(
            avatar: const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
            label: Text('${CollectionService.instance.gold}'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
    );
  }

  Widget _buildBattleButton() {
    return GestureDetector(
      onTap: _startSearching,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurpleAccent, Colors.redAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, size: 40, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              loc('battle_button'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return ListenableBuilder(
      listenable: ProfileService.instance,
      builder: (context, _) {
        final profile = ProfileService.instance;
        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.deepPurple.withOpacity(0.3),
                  child: Text(profile.avatar, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text('${profile.trophies}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: loc('settings_title'),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // RAKİP ARANIYOR
  // ---------------------------------------------------------------------

  Widget _buildSearching() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(strokeWidth: 5),
          ),
          const SizedBox(height: 24),
          Text(
            loc('searching_opponent'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (_showWaitingHint) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                loc('searching_waiting_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _cancelSearching,
            child: Text(loc('cancel_search')),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MAÇ (TAHTA)
  // ---------------------------------------------------------------------

  Widget _buildBoard() {
    final match = _match;
    if (match == null) {
      // Eşleşme az önce kuruldu ama ilk Firestore anlık görüntüsü (rakip
      // rengi, isim vb.) henüz gelmedi — kısa bir yükleme göstergesi.
      return const Center(child: CircularProgressIndicator());
    }
    final controller = match.controller;
    final selectedPiece = (selectedRow != null && selectedCol != null)
        ? controller.grid[selectedRow!][selectedCol!]
        : null;
    final canRewind = selectedPiece != null &&
        selectedPiece.ability == SpecialAbility.rewind &&
        !selectedPiece.specialUsed &&
        selectedPiece.team == controller.currentTurn &&
        match.isMyTurn &&
        controller.hasHistory;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: loc('return_to_lobby'),
                onPressed: _confirmLeaveMatch,
              ),
              Expanded(child: _buildStatusBar(match)),
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                tooltip: loc('resign_button'),
                onPressed: controller.winner == null ? _resign : null,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(match.opponentAvatar, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('${loc('opponent_label')}: ${match.opponentName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
        ),
        if (controller.winner == null && match.opponentSeemsAway)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 16, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc('opponent_away_hint'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (match.canClaimVictory)
                  TextButton(
                    onPressed: () async {
                      await match.claimVictoryByDisconnect();
                    },
                    child: Text(loc('claim_victory_button'),
                        style: const TextStyle(fontSize: 11, color: Colors.orangeAccent)),
                  ),
              ],
            ),
          ),
        if (canRewind)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ElevatedButton.icon(
              onPressed: _tryRewind,
              icon: const Icon(Icons.replay, size: 16),
              label: Text(loc('rewind_button')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            ),
          ),
        const Divider(height: 8),
        Expanded(
          child: Center(
            child: BoardGrid(
              controller: controller,
              selectedRow: selectedRow,
              selectedCol: selectedCol,
              highlightedMoves: highlightedMoves,
              onSquareTap: _onSquareTap,
              onPieceLongPress: _showPieceInfo,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(OnlineMatchController match) {
    final controller = match.controller;
    final isCheck = controller.lastMoveWasCheck && controller.winner == null;
    final isMyTurn = match.isMyTurn;
    final turnLabel = controller.winner != null
        ? ''
        : (isMyTurn ? loc('your_turn') : loc('opponent_turn'));
    final turnColor = controller.currentTurn == Team.white ? Colors.white : Colors.black87;

    return Row(
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
        Flexible(
          child: Text(
            turnLabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (isCheck) ...[
          const SizedBox(width: 12),
          Text(
            loc('check'),
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}
