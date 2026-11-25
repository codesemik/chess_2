import '../models/piece_library.dart';
import '../models/card_level_service.dart';

class Point {
  final int row;
  final int col;
  const Point(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Point && other.row == row && other.col == col;

  @override
  int get hashCode => row * 31 + col;
}

/// Kart Test Odası'nda belirli bir taşı belirli bir kareye yerleştirmek
/// için kullanılan basit bir veri sınıfı. [level] sadece Test Odası'ndaki
/// seviye seçiciyle değiştirilir; gerçek maçlarda [CardLevelService] kullanılır.
class ScenarioPlacement {
  final Piece piece;
  final Team team;
  final int row;
  final int col;
  final int level;
  const ScenarioPlacement(this.piece, this.team, this.row, this.col, {this.level = 1});
}

/// Zaman Lordu'nun "Geri Sarma" yeteneği için tahtanın bir hamle öncesindeki
/// tam halini saklar (taşların can/kalkan/kilit durumu dahil).
class _Snapshot {
  final List<List<Piece?>> grid;
  final Team currentTurn;
  final Team? winner;
  _Snapshot(this.grid, this.currentTurn, this.winner);
}

/// 4 sütun x 8 satırlık bir arenada gerçek satranç hareket mantığını
/// (Şah, Vezir, Piyon, At, Fil, Kale + onlarca özel yetenekli varyasyon)
/// uygulayan oyun kontrolcüsü. Sıra bazlı oynanır ve taşlar can (HP)
/// puanına sahiptir; bu da klasik satrancı "Chess 2" temasına uyarlar.
class BoardController {
  static const int rows = 8;
  static const int cols = 4;

  // 8 satır x 4 sütunluk boş matris
  List<List<Piece?>> grid = List.generate(
    rows,
    (_) => List<Piece?>.filled(cols, null),
  );

  Team currentTurn = Team.white;
  Team? winner;
  bool lastMoveWasCheck = false;

  /// TRUE olduğunda sıra/takım kontrolleri devre dışı kalır: herhangi bir
  /// taş, hangi takımdan olursa olsun, istenildiği zaman oynatılabilir.
  /// Sadece "Kart Test Odası" bunu kullanır; gerçek maçlarda her zaman false'tur.
  bool sandboxMode = false;

  /// Şaman'ın "Ruh Yolu" yeteneği için: her takımın kaybettiği piyon sayısı.
  final Map<Team, int> deadPawnCount = {Team.white: 0, Team.black: 0};

  /// Ejderha Kraliçe'nin "Alev Hattı" yeteneği için: hangi karelerin kaç
  /// tur daha "ateşte" (girilemez) olduğu.
  final Map<Point, int> firedSquares = {};

  /// Zaman Lordu'nun "Geri Sarma" yeteneği için hamle geçmişi.
  final List<_Snapshot> _history = [];

  bool get hasHistory => _history.isNotEmpty;

  bool _inBounds(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  bool isSquareOnFire(int row, int col) => firedSquares.containsKey(Point(row, col));

  /// Tahtayı tam bir diziliş (formasyon) ile kurar.
  /// [whitePawns] tam olarak 4 eleman içermelidir (A, B, C, D sütunları).
  /// Beyaz taraf oyuncunun "Kartlarım > Diziliş" ekranında seçtiği kartlardan,
  /// siyah taraf ise rakibin (varsayılan/AI) dizilişinden oluşur.
  void initBoard({
    required List<Piece> whitePawns,
    required Piece whiteDpsLeft,
    required Piece whiteDpsRight,
    required Piece whiteQueen,
    required Piece whiteKing,
    required List<Piece> blackPawns,
    required Piece blackDpsLeft,
    required Piece blackDpsRight,
    required Piece blackQueen,
    required Piece blackKing,
  }) {
    assert(whitePawns.length == cols, 'whitePawns tam olarak $cols eleman içermeli');
    assert(blackPawns.length == cols, 'blackPawns tam olarak $cols eleman içermeli');

    grid = List.generate(rows, (_) => List<Piece?>.filled(cols, null));
    currentTurn = Team.white;
    winner = null;
    lastMoveWasCheck = false;
    deadPawnCount[Team.white] = 0;
    deadPawnCount[Team.black] = 0;
    firedSquares.clear();
    _history.clear();
    sandboxMode = false;

    // --- SİYAH TAKIM (Satır 0 ve 1) --- (rakip: her zaman seviye 1)
    grid[0][0] = blackDpsLeft.copyWith(newTeam: Team.black, newId: 'b_dps_left');
    grid[0][1] = blackKing.copyWith(newTeam: Team.black, newId: 'b_king');
    grid[0][2] = blackQueen.copyWith(newTeam: Team.black, newId: 'b_queen');
    grid[0][3] = blackDpsRight.copyWith(newTeam: Team.black, newId: 'b_dps_right');

    for (int c = 0; c < cols; c++) {
      grid[1][c] = blackPawns[c].copyWith(newTeam: Team.black, newId: 'b_pawn_$c');
    }

    // --- BEYAZ TAKIM (Satır 6 ve 7) --- (oyuncu: kart seviyeleri uygulanır)
    for (int c = 0; c < cols; c++) {
      grid[6][c] = whitePawns[c].copyWith(
        newTeam: Team.white,
        newId: 'w_pawn_$c',
        level: CardLevelService.instance.levelOf(whitePawns[c].id),
      );
    }

    grid[7][0] = whiteDpsLeft.copyWith(
      newTeam: Team.white,
      newId: 'w_dps_left',
      level: CardLevelService.instance.levelOf(whiteDpsLeft.id),
    );
    grid[7][1] = whiteKing.copyWith(
      newTeam: Team.white,
      newId: 'w_king',
      level: CardLevelService.instance.levelOf(whiteKing.id),
    );
    grid[7][2] = whiteQueen.copyWith(
      newTeam: Team.white,
      newId: 'w_queen',
      level: CardLevelService.instance.levelOf(whiteQueen.id),
    );
    grid[7][3] = whiteDpsRight.copyWith(
      newTeam: Team.white,
      newId: 'w_dps_right',
      level: CardLevelService.instance.levelOf(whiteDpsRight.id),
    );
  }

  /// [initBoard] ile aynı işi yapar ama verilen taşların can/seviye/yetenek
  /// durumunu OLDUĞU GİBİ korur (tekrar seviye hesaplaması YAPMAZ — bu
  /// yüzden [CardLevelService]'e hiç bakmaz). Çevrimiçi bir maçın
  /// başlangıç durumunu, HER İKİ oyuncunun da kendi (buluttan okunan)
  /// seviyeleriyle doğru şekilde kurmak için kullanılır; bkz.
  /// `match_state_builder.dart`. Buraya verilen taşlar zaten
  /// `Piece.copyWith(level: ...)` ile önceden seviyelendirilmiş olmalı.
  void initBoardRaw({
    required List<Piece> whitePawns,
    required Piece whiteDpsLeft,
    required Piece whiteDpsRight,
    required Piece whiteQueen,
    required Piece whiteKing,
    required List<Piece> blackPawns,
    required Piece blackDpsLeft,
    required Piece blackDpsRight,
    required Piece blackQueen,
    required Piece blackKing,
  }) {
    assert(whitePawns.length == cols, 'whitePawns tam olarak $cols eleman içermeli');
    assert(blackPawns.length == cols, 'blackPawns tam olarak $cols eleman içermeli');

    grid = List.generate(rows, (_) => List<Piece?>.filled(cols, null));
    currentTurn = Team.white;
    winner = null;
    lastMoveWasCheck = false;
    deadPawnCount[Team.white] = 0;
    deadPawnCount[Team.black] = 0;
    firedSquares.clear();
    _history.clear();
    sandboxMode = false;

    grid[0][0] = blackDpsLeft.copyForPlacement(newTeam: Team.black, newId: 'b_dps_left');
    grid[0][1] = blackKing.copyForPlacement(newTeam: Team.black, newId: 'b_king');
    grid[0][2] = blackQueen.copyForPlacement(newTeam: Team.black, newId: 'b_queen');
    grid[0][3] = blackDpsRight.copyForPlacement(newTeam: Team.black, newId: 'b_dps_right');
    for (int c = 0; c < cols; c++) {
      grid[1][c] = blackPawns[c].copyForPlacement(newTeam: Team.black, newId: 'b_pawn_$c');
    }

    grid[7][0] = whiteDpsLeft.copyForPlacement(newTeam: Team.white, newId: 'w_dps_left');
    grid[7][1] = whiteKing.copyForPlacement(newTeam: Team.white, newId: 'w_king');
    grid[7][2] = whiteQueen.copyForPlacement(newTeam: Team.white, newId: 'w_queen');
    grid[7][3] = whiteDpsRight.copyForPlacement(newTeam: Team.white, newId: 'w_dps_right');
    for (int c = 0; c < cols; c++) {
      grid[6][c] = whitePawns[c].copyForPlacement(newTeam: Team.white, newId: 'w_pawn_$c');
    }
  }

  /// Mevcut TÜM tahta durumunu (taşlar, can, seviye, kalkan, kilit, sıra,
  /// kazanan, ateşteki kareler) Firestore'a yazılabilir düz bir haritaya
  /// çevirir. Firestore iç içe dizi (array içinde array) desteklemediği
  /// için 8x4'lük tahta TEK boyutlu, 32 elemanlı bir diziye yassıltılır
  /// (indeks = satır*4 + sütun).
  Map<String, dynamic> toMatchStateJson() {
    final flatGrid = <Map<String, dynamic>?>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        flatGrid.add(grid[r][c]?.toJson());
      }
    }
    return {
      'grid': flatGrid,
      'currentTurn': currentTurn.name,
      'winner': winner?.name,
      'lastMoveWasCheck': lastMoveWasCheck,
      'deadPawnCountWhite': deadPawnCount[Team.white] ?? 0,
      'deadPawnCountBlack': deadPawnCount[Team.black] ?? 0,
      'firedSquares': firedSquares.map((k, v) => MapEntry('${k.row}_${k.col}', v)),
    };
  }

  /// [toMatchStateJson] ile üretilmiş bir durumu bu controller'a yükler.
  /// Rakibin hamlesi bu şekilde bize ulaşır. Yüklemeden önce mevcut
  /// durumu geçmişe ([_history]) atar ki Zaman Lordu, rakibin hamlesini
  /// bile "Geri Sar"abilsin.
  void loadFromMatchStateJson(Map<String, dynamic> json) {
    _pushSnapshot();

    final flatGrid = json['grid'] as List;
    grid = List.generate(rows, (_) => List<Piece?>.filled(cols, null));
    for (int i = 0; i < flatGrid.length && i < rows * cols; i++) {
      final cell = flatGrid[i];
      if (cell != null) {
        final r = i ~/ cols;
        final c = i % cols;
        grid[r][c] = Piece.fromJson(Map<String, dynamic>.from(cell as Map));
      }
    }

    currentTurn = json['currentTurn'] == 'black' ? Team.black : Team.white;
    final w = json['winner'];
    winner = w == 'white' ? Team.white : (w == 'black' ? Team.black : null);
    lastMoveWasCheck = json['lastMoveWasCheck'] as bool? ?? false;
    deadPawnCount[Team.white] = (json['deadPawnCountWhite'] as num?)?.toInt() ?? 0;
    deadPawnCount[Team.black] = (json['deadPawnCountBlack'] as num?)?.toInt() ?? 0;

    firedSquares.clear();
    final fs = json['firedSquares'];
    if (fs is Map) {
      fs.forEach((key, value) {
        final parts = key.toString().split('_');
        if (parts.length == 2) {
          final r = int.tryParse(parts[0]);
          final c = int.tryParse(parts[1]);
          if (r != null && c != null && value is num) {
            firedSquares[Point(r, c)] = value.toInt();
          }
        }
      });
    }
    sandboxMode = false;
  }

  /// Kart Test Odası için: tahtayı gerçek maç dizilimi yerine, belirli bir
  /// kartın yeteneğini göstermek üzere hazırlanmış özel bir senaryo ile
  /// kurar. Sıra/takım kısıtlaması olmadan ([sandboxMode]) her taş serbestçe
  /// denenebilir.
  void loadScenario(
    List<ScenarioPlacement> placements, {
    Map<Team, int>? presetDeadPawns,
  }) {
    grid = List.generate(rows, (_) => List<Piece?>.filled(cols, null));
    currentTurn = Team.white;
    winner = null;
    lastMoveWasCheck = false;
    deadPawnCount[Team.white] = 0;
    deadPawnCount[Team.black] = 0;
    firedSquares.clear();
    _history.clear();
    sandboxMode = true;

    for (final p in placements) {
      grid[p.row][p.col] = p.piece.copyWith(
        newTeam: p.team,
        newId: '${p.piece.id}_test_${p.row}_${p.col}',
        level: p.level,
      );
    }
    if (presetDeadPawns != null) {
      deadPawnCount.addAll(presetDeadPawns);
    }
  }

  // ---------------------------------------------------------------------
  // HAREKET ÜRETİMİ (gerçek satranç kuralları + özel yetenekler)
  // ---------------------------------------------------------------------

  static const List<Point> _kingOffsets = [
    Point(-1, -1), Point(-1, 0), Point(-1, 1),
    Point(0, -1), Point(0, 1),
    Point(1, -1), Point(1, 0), Point(1, 1),
  ];

  static const List<Point> _knightOffsets = [
    Point(-2, -1), Point(-2, 1), Point(-1, -2), Point(-1, 2),
    Point(1, -2), Point(1, 2), Point(2, -1), Point(2, 1),
  ];

  static const List<Point> _rookDirs = [
    Point(-1, 0), Point(1, 0), Point(0, -1), Point(0, 1),
  ];

  static const List<Point> _bishopDirs = [
    Point(-1, -1), Point(-1, 1), Point(1, -1), Point(1, 1),
  ];

  static const List<Point> _mainDiag = [Point(-1, -1), Point(1, 1)];
  static const List<Point> _antiDiag = [Point(-1, 1), Point(1, -1)];

  /// Belirtilen karedeki taşın gidebileceği tüm kareleri
  /// (boş kareler + rakip yeme kareleri + özel yetenek hedefleri) döndürür.
  /// Sıra kontrolü YAPMAZ; bu saf bir "bu taş nereye gidebilir" hesabıdır.
  List<Point> rawMovesFor(int row, int col) {
    final piece = grid[row][col];
    if (piece == null) return [];
    if (piece.frozenTurns > 0) return []; // Korku Halesi ile kilitlenmiş

    List<Point> moves;
    switch (piece.moveStyle) {
      case MoveStyle.kingStyle:
        moves = _stepMoves(row, col, piece, _kingOffsets);
        break;
      case MoveStyle.knightStyle:
        moves = _knightMoves(row, col, piece);
        break;
      case MoveStyle.rookStyle:
        moves = piece.ability == SpecialAbility.catapultStrike
            ? _catapultTargets(row, col, piece)
            : _slidingMoves(row, col, piece, _rookDirs);
        break;
      case MoveStyle.bishopStyle:
        moves = _slidingMoves(row, col, piece, _bishopDirs);
        if (piece.ability == SpecialAbility.mirrorReflection && !piece.specialUsed) {
          moves = [...moves, ..._mirrorMoves(row, col, piece)];
        }
        if (piece.ability == SpecialAbility.spiritPath &&
            (deadPawnCount[piece.team] ?? 0) > 0) {
          moves = [...moves, ..._shamanBentMoves(row, col, piece)];
        }
        break;
      case MoveStyle.queenStyle:
        moves = _slidingMoves(row, col, piece, [..._rookDirs, ..._bishopDirs]);
        break;
      case MoveStyle.pawnStyle:
        moves = _pawnMoves(row, col, piece);
        break;
    }

    // Ateşteki karelere hiçbir taş giremez (Ejderha Kraliçe: Alev Hattı)
    if (firedSquares.isNotEmpty) {
      moves = moves.where((p) => !firedSquares.containsKey(p)).toList();
    }
    return moves;
  }

  /// Oyuncuya gösterilecek "oynanabilir" hareketler: sıra kontrolünü de içerir
  /// ([sandboxMode] açıkken bu kontrol atlanır).
  List<Point> legalMovesFor(int row, int col) {
    final piece = grid[row][col];
    if (piece == null) return [];
    if (!sandboxMode && piece.team != currentTurn) return [];
    if (winner != null) return [];
    return rawMovesFor(row, col);
  }

  List<Point> _stepMoves(int row, int col, Piece piece, List<Point> offsets) {
    final result = <Point>[];
    for (final o in offsets) {
      final r = row + o.row;
      final c = col + o.col;
      if (!_inBounds(r, c)) continue;
      final target = grid[r][c];
      if (target == null || target.team != piece.team) {
        result.add(Point(r, c));
      }
    }
    return result;
  }

  /// At tarzı sıçramalar. Hedefte rakip varsa ve o rakip bir Barikat
  /// Kalesi'ne bitişikse (kendi takımından), sıçrama engellenir.
  List<Point> _knightMoves(int row, int col, Piece piece) {
    final base = _stepMoves(row, col, piece, _knightOffsets);
    return base.where((p) {
      final target = grid[p.row][p.col];
      if (target == null || target.team == piece.team) return true;
      return !_isProtectedByBarricade(p, target.team);
    }).toList();
  }

  bool _isProtectedByBarricade(Point square, Team protectedTeam) {
    for (final d in _rookDirs) {
      final r = square.row + d.row;
      final c = square.col + d.col;
      if (!_inBounds(r, c)) continue;
      final p = grid[r][c];
      if (p != null && p.team == protectedTeam && p.ability == SpecialAbility.barricade) {
        return true;
      }
    }
    return false;
  }

  List<Point> _slidingMoves(int row, int col, Piece piece, List<Point> dirs) {
    final result = <Point>[];
    for (final d in dirs) {
      int r = row + d.row;
      int c = col + d.col;
      while (_inBounds(r, c)) {
        final target = grid[r][c];
        if (target == null) {
          result.add(Point(r, c));
        } else {
          if (target.team != piece.team) result.add(Point(r, c));
          break; // Kendi taşı ya da rakip taş: bu yönde daha ileri gidilemez
        }
        r += d.row;
        c += d.col;
      }
    }
    return result;
  }

  /// Mancınık Kulesi: hareket etmez, sadece düz hatta TAM 3 kare uzaktaki
  /// bir rakibi (aradaki taşları görmezden gelerek) hedef alabilir.
  List<Point> _catapultTargets(int row, int col, Piece piece) {
    final result = <Point>[];
    for (final d in _rookDirs) {
      final r = row + d.row * 3;
      final c = col + d.col * 3;
      if (!_inBounds(r, c)) continue;
      final target = grid[r][c];
      if (target != null && target.team != piece.team) {
        result.add(Point(r, c));
      }
    }
    return result;
  }

  /// Büyücü: Ayna Yansıması. Boş, dik/yatay bitişik bir kareye kayabilir
  /// (bu, normal Fil hareketinden farklı olarak köşegen DEĞİL, ortogonaldir).
  List<Point> _mirrorMoves(int row, int col, Piece piece) {
    final result = <Point>[];
    for (final d in _rookDirs) {
      final r = row + d.row;
      final c = col + d.col;
      if (_inBounds(r, c) && grid[r][c] == null) {
        result.add(Point(r, c));
      }
    }
    return result;
  }

  /// Şaman: Ruh Yolu. Bir dost piyon öldüyse, çapraz hattı boyunca
  /// ilerlerken bir kez 90° kırıp diğer çapraz aileye geçebilir
  /// (ör. sağ-üst yönünde giderken sol-üst/sağ-alt yönüne dönebilir).
  List<Point> _shamanBentMoves(int row, int col, Piece piece) {
    final result = <Point>[];
    for (final d1 in _bishopDirs) {
      int r = row + d1.row;
      int c = col + d1.col;
      final bendDirs = _mainDiag.contains(d1) ? _antiDiag : _mainDiag;
      while (_inBounds(r, c) && grid[r][c] == null) {
        for (final d2 in bendDirs) {
          int r2 = r + d2.row;
          int c2 = c + d2.col;
          while (_inBounds(r2, c2)) {
            final target = grid[r2][c2];
            if (target == null) {
              result.add(Point(r2, c2));
            } else {
              if (target.team != piece.team) result.add(Point(r2, c2));
              break;
            }
            r2 += d2.row;
            c2 += d2.col;
          }
        }
        r += d1.row;
        c += d1.col;
      }
    }
    return result;
  }

  List<Point> _pawnMoves(int row, int col, Piece piece) {
    final result = <Point>[];
    final forward = piece.team == Team.white ? -1 : 1;
    final startRow = piece.team == Team.white ? 6 : 1;

    // Düz ilerleme (yeme yok)
    final oneStepR = row + forward;
    if (_inBounds(oneStepR, col) && grid[oneStepR][col] == null) {
      result.add(Point(oneStepR, col));

      final twoStepR = row + forward * 2;
      if (row == startRow && _inBounds(twoStepR, col) && grid[twoStepR][col] == null) {
        result.add(Point(twoStepR, col));

        // Sipahi: Süvari Hücumu — ilk hamlesinde 3 kareye kadar gidebilir
        if (piece.ability == SpecialAbility.cavalryRush) {
          final threeStepR = row + forward * 3;
          if (_inBounds(threeStepR, col) && grid[threeStepR][col] == null) {
            result.add(Point(threeStepR, col));
          }
        }
      }
    }

    // Çapraz vuruş (+ Gölge Piyonu: Kör Nokta)
    for (final dc in [-1, 1]) {
      final r = row + forward;
      final c = col + dc;
      if (!_inBounds(r, c)) continue;
      final target = grid[r][c];
      if (target != null && target.team != piece.team) {
        result.add(Point(r, c));
      }
      if (piece.ability == SpecialAbility.blindSpotStrike) {
        // Önündeki karede ne olursa olsun (boş/dost/düşman), 2 kare
        // çaprazdaki bir düşmanı üzerinden aşarak hedefleyebilir.
        final r2 = row + forward * 2;
        final c2 = col + dc * 2;
        if (_inBounds(r2, c2)) {
          final target2 = grid[r2][c2];
          if (target2 != null && target2.team != piece.team) {
            result.add(Point(r2, c2));
          }
        }
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------
  // ŞAH KONTROLÜ
  // ---------------------------------------------------------------------

  Point? _findKing(Team team) {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = grid[r][c];
        // KRİTİK: type değil, role bakılır — yoksa Zırhlı Şah gibi
        // varyasyonlar "şah" olarak tanınmaz ve şah çekilemez.
        if (p != null && p.isKingPiece && p.team == team) {
          return Point(r, c);
        }
      }
    }
    return null;
  }

  /// Verilen takımın şahı rakip taşlardan biri tarafından tehdit ediliyor mu?
  bool isTeamInCheck(Team team) {
    final kingPos = _findKing(team);
    if (kingPos == null) return false;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = grid[r][c];
        if (p == null || p.team == team) continue;
        if (rawMovesFor(r, c).contains(kingPos)) return true;
      }
    }
    return false;
  }

  int _pawnAliveCount(Team team) {
    int count = 0;
    for (final row in grid) {
      for (final p in row) {
        // KRİTİK: type değil, role bakılır — yoksa Goblin gibi piyon
        // rolündeki taşlar "piyon" sayılmaz.
        if (p != null && p.team == team && p.isPawnPiece) count++;
      }
    }
    return count;
  }

  // ---------------------------------------------------------------------
  // HAREKET UYGULAMA
  // ---------------------------------------------------------------------

  /// Bir taşı oynar. Sadece [legalMovesFor] tarafından üretilen kareler
  /// kabul edilir; kural dışı hareketler yok sayılır.
  /// Döner: hamle gerçekleştiyse true.
  bool movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    if (winner != null) return false;
    final source = grid[fromRow][fromCol];
    if (source == null) return false;
    if (!sandboxMode && source.team != currentTurn) return false;

    final legal = legalMovesFor(fromRow, fromCol);
    if (!legal.contains(Point(toRow, toCol))) return false;

    _pushSnapshot();

    final target = grid[toRow][toCol];

    // --- Ölüçağıran Şah: Ruh Çağırma (boş kareye "yürümek" yerine çağırma) ---
    if (source.isKingPiece &&
        source.ability == SpecialAbility.soulSummon &&
        !source.specialUsed &&
        target == null &&
        _pawnAliveCount(source.team) == 0) {
      grid[toRow][toCol] = Piece(
        id: '${source.id}_summon_${toRow}_$toCol',
        nameKey: 'piece_pawn',
        type: PieceType.pawn,
        team: source.team,
        moveStyle: MoveStyle.pawnStyle,
        emoji: source.team == Team.white ? '💀' : '☠️',
        hp: 1,
        maxHp: 1,
        attackPower: 1,
      );
      source.consumeUse();
      _finishTurn();
      return true;
    }

    // --- Mancınık Kulesi: Uzak Atış (yerinden kıpırdamadan vurur) ---
    if (source.ability == SpecialAbility.catapultStrike && target != null && target.team != source.team) {
      _dealDamage(source, target, fromRow, fromCol, toRow, toCol, relocateAttacker: false);
      _finishTurn();
      return true;
    }

    // --- Büyücü: Ayna Yansıması (ortogonal 1 kare kayma, normal Fil hareketinden ayrıdır) ---
    if (source.ability == SpecialAbility.mirrorReflection && !source.specialUsed && target == null) {
      final isOrthogonalStep = (fromRow == toRow && (fromCol - toCol).abs() == 1) ||
          (fromCol == toCol && (fromRow - toRow).abs() == 1);
      if (isOrthogonalStep) {
        grid[toRow][toCol] = source;
        grid[fromRow][fromCol] = null;
        source.consumeUse();
        _finishTurn();
        return true;
      }
    }

    // --- Normal hareket / saldırı ---
    if (target != null && target.team != source.team) {
      _dealDamage(source, target, fromRow, fromCol, toRow, toCol, relocateAttacker: true);
    } else if (target == null) {
      grid[toRow][toCol] = source;
      grid[fromRow][fromCol] = null;
    }

    _maybePromote(toRow, toCol);
    if (grid[toRow][toCol] == source && source.moveStyle == MoveStyle.knightStyle) {
      _applyKnightAuraEffects(source, toRow, toCol);
    }

    _finishTurn();
    return true;
  }

  /// Hasar uygulama mantığı: kalkan/Taş Deri gibi savunma yeteneklerini,
  /// ölüm durumunda saldırganın kareye geçip geçmeyeceğini (Mancınık hariç)
  /// ve Alev Hattı gibi vuruş-sonrası etkilerini yönetir.
  void _dealDamage(
    Piece attacker,
    Piece target,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol, {
    required bool relocateAttacker,
  }) {
    bool absorbed = false;

    if (target.shieldTurns > 0) {
      // Pegasus'un verdiği kalkan bu hasarı tamamen söndürür.
      absorbed = true;
    } else if (target.ability == SpecialAbility.stoneSkin &&
        !target.stoneSkinUsed &&
        (target.hp - attacker.attackPower) <= 0) {
      // Maden Muhafızı: Taş Deri — ölümcül vuruşu absorbe eder (seviyeye göre
      // birden fazla kez hayatta kalabilir).
      target.consumeStoneSkinCharge();
      target.hp = 1;
      absorbed = true;
    } else {
      target.hp -= attacker.attackPower;
    }

    if (absorbed || target.hp > 0) return; // Taş hayatta kaldı, yer değişimi yok

    // Taş öldü. KRİTİK: type değil, role bakılır (bkz. Piece.isKingPiece/isPawnPiece).
    if (target.isKingPiece) winner = attacker.team;
    if (target.isPawnPiece) {
      deadPawnCount[target.team] = (deadPawnCount[target.team] ?? 0) + 1;
    }

    if (relocateAttacker) {
      grid[toRow][toCol] = attacker;
      grid[fromRow][fromCol] = null;
      _applyFlameLine(attacker, fromRow, fromCol, toRow, toCol);
    } else {
      // Mancınık Kulesi: hedef ortadan kalkar, saldırgan yerinde kalır.
      grid[toRow][toCol] = null;
    }
  }

  /// Ejderha Kraliçe: Alev Hattı. Bir vuruşla düşman elendiğinde, geldiği
  /// doğrultuda hedefin bir kare arkasını (seviyeye göre) birkaç tur boyunca
  /// ateşe verir.
  void _applyFlameLine(Piece attacker, int fromRow, int fromCol, int toRow, int toCol) {
    if (attacker.ability != SpecialAbility.flameLine) return;
    final dirRow = (toRow - fromRow).sign;
    final dirCol = (toCol - fromCol).sign;
    final fireR = toRow + dirRow;
    final fireC = toCol + dirCol;
    if (_inBounds(fireR, fireC)) {
      firedSquares[Point(fireR, fireC)] = attacker.level;
    }
  }

  /// Pegasus (kalkan) / Kabus (kilitleme): At tarzı bir hamle tamamlandığında
  /// iniş karesinin çevresindeki 8 kareye etki eder.
  void _applyKnightAuraEffects(Piece mover, int landRow, int landCol) {
    if (mover.ability != SpecialAbility.windGlideShield &&
        mover.ability != SpecialAbility.fearAura) {
      return;
    }
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final r = landRow + dr;
        final c = landCol + dc;
        if (!_inBounds(r, c)) continue;
        final p = grid[r][c];
        if (p == null) continue;

        if (mover.ability == SpecialAbility.windGlideShield &&
            p.team == mover.team &&
            p.isPawnPiece) {
          p.shieldTurns = mover.level;
        } else if (mover.ability == SpecialAbility.fearAura &&
            p.team != mover.team &&
            (p.isPawnPiece ||
                p.moveStyle == MoveStyle.rookStyle ||
                p.moveStyle == MoveStyle.bishopStyle)) {
          p.frozenTurns = mover.level;
        }
      }
    }
  }

  /// Piyon (ya da piyon rolündeki herhangi bir kart — Sipahi, Goblin vb.)
  /// karşı son sıraya ulaştıysa otomatik olarak Vezir'e terfi eder.
  /// KRİTİK: type değil, role bakılır — yoksa piyon türevleri hiç terfi edemez.
  void _maybePromote(int row, int col) {
    final piece = grid[row][col];
    if (piece == null || !piece.isPawnPiece) return;
    final promotionRow = piece.team == Team.white ? 0 : rows - 1;
    if (row != promotionRow) return;

    grid[row][col] = Piece(
      id: '${piece.id}_promoted',
      nameKey: 'piece_queen',
      type: PieceType.queen,
      team: piece.team,
      moveStyle: MoveStyle.queenStyle,
      emoji: piece.team == Team.white ? '♕' : '♛',
      hp: 2,
      maxHp: 2,
      attackPower: 2,
    );
  }

  void _finishTurn() {
    if (winner == null) {
      // Sandbox modunda sıra hiç değişmez: istediğin takımın taşını
      // istediğin an oynatabilesin diye (Kart Test Odası).
      if (!sandboxMode) {
        currentTurn = currentTurn == Team.white ? Team.black : Team.white;
      }
      _tickStatuses();
      lastMoveWasCheck = isTeamInCheck(currentTurn);
    } else {
      lastMoveWasCheck = false;
    }
  }

  /// Her tam hamle sonunda geçici durumları (kalkan, kilit, ateş) 1 azaltır.
  void _tickStatuses() {
    for (final row in grid) {
      for (final p in row) {
        if (p == null) continue;
        if (p.shieldTurns > 0) p.shieldTurns--;
        if (p.frozenTurns > 0) p.frozenTurns--;
      }
    }
    final expired = <Point>[];
    firedSquares.forEach((key, turnsLeft) {
      if (turnsLeft <= 1) {
        expired.add(key);
      } else {
        firedSquares[key] = turnsLeft - 1;
      }
    });
    for (final key in expired) {
      firedSquares.remove(key);
    }
  }

  // ---------------------------------------------------------------------
  // ZAMAN LORDU: GERİ SARMA
  // ---------------------------------------------------------------------

  void _pushSnapshot() {
    final cloned = grid.map((row) => row.map((p) => p?.clone()).toList()).toList();
    _history.add(_Snapshot(cloned, currentTurn, winner));
    if (_history.length > 20) _history.removeAt(0); // Bellek şişmesin
  }

  /// [actor] (bir Zaman Lordu) rakibin bir önceki hamlesini iptal eder ve
  /// tahtayı o hamleden önceki haline döndürür. Sıra yine [actor]'ın
  /// takımında kalır; böylece "ekstra hamle" kazanılmış olur.
  /// Sadece [actor]'ın kendi sırasında ve oyunda bir kez kullanılabilir.
  bool rewind(Piece actor) {
    if (actor.ability != SpecialAbility.rewind) return false;
    if (actor.specialUsed) return false;
    if (actor.team != currentTurn) return false;
    if (_history.isEmpty) return false;

    final snap = _history.removeLast();
    grid = snap.grid;
    winner = snap.winner;
    currentTurn = actor.team; // Rakibin hamlesi iptal edildi, sıra yine sende
    lastMoveWasCheck = isTeamInCheck(currentTurn);

    for (final row in grid) {
      for (final p in row) {
        if (p != null && p.id == actor.id) {
          p.consumeUse();
        }
      }
    }
    return true;
  }
}
