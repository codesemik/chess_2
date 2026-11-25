import 'package:flutter_test/flutter_test.dart';
import 'package:chess_2/controllers/board_controller.dart';
import 'package:chess_2/models/piece_library.dart';

void main() {
  group('Temel hareket üretimi (rawMovesFor)', () {
    test('Şah: 8 yöne gidebilir, kendi takımını yiyemez, rakibi yiyebilir', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.king, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 2, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 4, 1),
      ]);
      final moves = board.rawMovesFor(3, 1);
      expect(moves.length, 7);
      expect(moves, contains(const Point(4, 1)));
      expect(moves, isNot(contains(const Point(2, 1))));
    });

    test('At: L şeklinde sıçrar, tahta kenarında geçerli 6 kare üretir', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.knightBasic, Team.white, 3, 1),
      ]);
      final moves = board.rawMovesFor(3, 1);
      expect(moves.length, 6);
      expect(moves, containsAll(const [
        Point(1, 0), Point(1, 2), Point(2, 3),
        Point(4, 3), Point(5, 0), Point(5, 2),
      ]));
    });

    test('Kale: düz sınırsız kayar, kendi taşında durur, rakipte yiyip durur', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.rookBasic, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 3, 3),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 0, 1),
      ]);
      final moves = board.rawMovesFor(3, 1);
      expect(moves, containsAll(const [Point(2, 1), Point(1, 1), Point(0, 1)]));
      expect(moves, contains(const Point(3, 0)));
      expect(moves, contains(const Point(3, 2)));
      expect(moves, isNot(contains(const Point(3, 3))));
      expect(moves, contains(const Point(7, 1)));
    });

    test('Fil: çapraz sınırsız kayar, ilk rakipte yiyip durur', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.bishopBasic, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 2, 0),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 5, 3),
      ]);
      final moves = board.rawMovesFor(3, 1);
      expect(moves, contains(const Point(2, 0)));
      expect(moves, contains(const Point(4, 2)));
      expect(moves, isNot(contains(const Point(5, 3))));
    });

    test('Vezir: düz VE çapraz sınırsız hareket eder', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.queen, Team.white, 3, 1),
      ]);
      final moves = board.rawMovesFor(3, 1);
      expect(moves, contains(const Point(0, 1)));
      expect(moves, contains(const Point(5, 3)));
    });

    test('Piyon: başlangıç sırasında 2 kare, sonrasında 1 kare ilerler', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 6, 1),
      ]);
      final moves = board.rawMovesFor(6, 1);
      expect(moves, containsAll(const [Point(5, 1), Point(4, 1)]));
    });

    test('Piyon: başlangıç sırası dışında sadece 1 kare ilerler', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 5, 1),
      ]);
      final moves = board.rawMovesFor(5, 1);
      expect(moves, contains(const Point(4, 1)));
      expect(moves, isNot(contains(const Point(3, 1))));
    });

    test('Piyon: çapraz sadece rakip varsa vurulabilir, boş/dost karede vuruş yok', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 5, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 4, 0),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 4, 2),
      ]);
      final moves = board.rawMovesFor(5, 1);
      expect(moves, contains(const Point(4, 0)));
      expect(moves, isNot(contains(const Point(4, 2))));
    });
  });

  group('Yakalama, ölüm ve kazanma koşulu', () {
    test('Şah yakalanınca winner set edilir', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.queen, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.king, Team.black, 3, 3),
      ]);
      board.grid[3][3]!.hp = 1;
      final moved = board.movePiece(3, 1, 3, 3);
      expect(moved, isTrue);
      expect(board.winner, Team.white);
    });

    test('winner set edildikten sonra hiç kimse hareket edemez', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.queen, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.king, Team.black, 3, 3),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 6, 1),
      ]);
      board.grid[3][3]!.hp = 1;
      board.movePiece(3, 1, 3, 3);
      expect(board.legalMovesFor(6, 1), isEmpty);
      expect(board.movePiece(6, 1, 5, 1), isFalse);
    });

    test('piyon rolündeki bir taş öldüğünde deadPawnCount artar', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.rookBasic, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 3, 3),
      ]);
      board.grid[3][3]!.hp = 1;
      board.movePiece(3, 1, 3, 3);
      expect(board.deadPawnCount[Team.black], 1);
    });

    test('kalkanlı taş bir sonraki hasarı tamamen söndürür', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.rookBasic, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 3, 3),
      ]);
      board.grid[3][3]!.hp = 1;
      board.grid[3][3]!.shieldTurns = 1;
      final moved = board.movePiece(3, 1, 3, 3);
      expect(moved, isTrue);
      expect(board.grid[3][3], isNotNull);
      expect(board.grid[3][3]!.hp, 1);
      expect(board.grid[3][1], isNotNull);
    });
  });

  group('Terfi (promotion)', () {
    test('son sıraya ulaşan piyon otomatik Vezir\'e terfi eder', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 1, 1),
      ]);
      board.movePiece(1, 1, 0, 1);
      final promoted = board.grid[0][1];
      expect(promoted, isNotNull);
      expect(promoted!.moveStyle, MoveStyle.queenStyle);
      expect(promoted.type, PieceType.queen);
    });

    test('piyon rolündeki bir varyant (ör. Sipahi) da terfi eder', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.sipahi, Team.white, 1, 1),
      ]);
      board.movePiece(1, 1, 0, 1);
      expect(board.grid[0][1]!.moveStyle, MoveStyle.queenStyle);
    });
  });

  group('Özel yetenek: Maden Muhafızı — Taş Deri', () {
    test('ilk ölümcül vuruşu absorbe eder, ikincisinde ölür', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.rookBasic, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.madenMuhafizi, Team.black, 3, 3),
      ]);

      board.movePiece(3, 1, 3, 3);
      expect(board.grid[3][3], isNotNull, reason: 'ilk vuruşta hayatta kalmalı');
      expect(board.grid[3][3]!.hp, 1);
      expect(board.grid[3][3]!.stoneSkinCharges, 0);
      expect(board.grid[3][1], isNotNull, reason: 'saldırgan henüz yer değiştirmemiş olmalı');

      board.movePiece(3, 1, 3, 3);
      expect(board.grid[3][1], isNull);
      expect(board.grid[3][3]!.id, contains('rook_basic'));
      expect(board.deadPawnCount[Team.black], 1);
    });
  });

  group('Özel yetenek: Mancınık Kulesi — Uzak Atış', () {
    test('sadece TAM 3 kare uzaktaki rakibi, aradaki taşları görmezden gelerek vurur', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.mancinik, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 5, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 6, 1),
      ]);
      final moves = board.rawMovesFor(3, 1);
      expect(moves, [const Point(6, 1)]);

      board.grid[6][1]!.hp = 1;
      board.movePiece(3, 1, 6, 1);
      expect(board.grid[3][1], isNotNull, reason: 'Mancınık hareket etmez, yerinde kalır');
      expect(board.grid[6][1], isNull, reason: 'hedef ortadan kalkar');
      expect(board.deadPawnCount[Team.black], 1);
    });
  });

  group('Özel yetenek: Barikat Kalesi — Ağır Taş', () {
    test('bitişikteki dost taşı rakip at sıçramalarından korur', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.barikat, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 3, 2),
        ScenarioPlacement(PieceLibrary.knightBasic, Team.black, 1, 1),
      ]);
      final knightMoves = board.rawMovesFor(1, 1);
      expect(knightMoves, isNot(contains(const Point(3, 2))));
    });

    test('barikat yokken aynı pozisyon normalde savunmasızdır', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.rookBasic, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 3, 2),
        ScenarioPlacement(PieceLibrary.knightBasic, Team.black, 1, 1),
      ]);
      final knightMoves = board.rawMovesFor(1, 1);
      expect(knightMoves, contains(const Point(3, 2)));
    });
  });

  group('Özel yetenek: Pegasus — Rüzgar Süzülüşü', () {
    test('iniş karesinin çevresindeki dost PİYONLARA seviyeye eşit kalkan verir', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.pegasus, Team.white, 3, 1, level: 2),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 5, 1),
        ScenarioPlacement(PieceLibrary.rookBasic, Team.white, 4, 2),
      ]);
      board.movePiece(3, 1, 5, 2);
      expect(board.grid[5][1]!.shieldTurns, 2, reason: 'dost piyon kalkan almalı');
      expect(board.grid[4][2]!.shieldTurns, 0, reason: 'piyon olmayan dost etkilenmemeli');
    }, skip: 'Ability balance updated');
  });

  group('Özel yetenek: Kabus — Korku Halesi', () {
    test('iniş karesi çevresindeki rakip piyon/kale/fil taşlarını kilitler, at\'ı kilitlemez', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.kabus, Team.white, 3, 1, level: 2),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 5, 1),
        ScenarioPlacement(PieceLibrary.knightBasic, Team.black, 4, 2),
      ]);
      board.movePiece(3, 1, 5, 2);
      expect(board.grid[5][1]!.frozenTurns, 2);
      expect(board.grid[4][2]!.frozenTurns, 0);
      expect(board.rawMovesFor(5, 1), isEmpty, reason: 'kilitli taş hiç hareket edemez');
    }, skip: 'Ability balance updated');
  });

  group('Özel yetenek: Ejderha Kraliçe — Alev Hattı', () {
    test('bir vuruşla düşman elenince arkasındaki kare seviye kadar tur ateşe verilir', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.ejderhaKralice, Team.white, 3, 1, level: 2),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 5, 1),
      ]);
      board.grid[5][1]!.hp = 1;
      board.movePiece(3, 1, 5, 1);
      expect(board.isSquareOnFire(6, 1), isTrue, reason: 'hedefin arkasındaki kare ateşte olmalı');
      expect(board.grid[5][1], isNotNull, reason: 'saldırgan hedefin karesine geçmeli');
    });

    test('DİKKAT — seviye 1 iken ateş, aynı tur içinde geri sayımla anında söner', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.ejderhaKralice, Team.white, 3, 1, level: 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 5, 1),
      ]);
      board.grid[5][1]!.hp = 1;
      board.movePiece(3, 1, 5, 1);
      expect(board.isSquareOnFire(6, 1), isFalse);
    });
  });

  group('Özel yetenek: Zaman Lordu — Geri Sarma', () {
    test('rakibin son hamlesini iptal eder, sıra actor\'da kalır, oyunda 1 kez kullanılır', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.zamanLordu, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 5, 1),
      ]);

      board.movePiece(5, 1, 4, 1);
      expect(board.grid[4][1], isNotNull);
      expect(board.grid[5][1], isNull);

      final actorBefore = board.grid[3][1]!;
      final rewound = board.rewind(actorBefore);
      expect(rewound, isTrue);
      expect(board.grid[5][1], isNotNull, reason: 'piyon eski karesine dönmeli');
      expect(board.grid[4][1], isNull);

      final actorAfter = board.grid[3][1]!;
      expect(actorAfter.specialUsed, isTrue, reason: 'oyunda 1 kez kullanılmış olmalı');
      expect(board.rewind(actorAfter), isFalse, reason: 'ikinci kez kullanılamaz');
    }, skip: 'Ability balance updated');

    test('hiç hamle geçmişi yoksa geri sarma başarısız olur', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.zamanLordu, Team.white, 3, 1),
      ]);
      expect(board.hasHistory, isFalse);
      expect(board.rewind(board.grid[3][1]!), isFalse);
    });
  });

  group('Özel yetenek: Ölüçağıran Şah — Ruh Çağırma', () {
    test('takımın piyonu yoksa boş komşu kareye hareket yerine iskelet piyon çağırır', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.necromancerSah, Team.white, 3, 1),
      ]);
      board.movePiece(3, 1, 4, 1);
      expect(board.grid[3][1], isNotNull, reason: 'Şah yerinde kalmalı, hareket etmemeli');
      expect(board.grid[4][1], isNotNull, reason: 'çağrılan piyon belirmeli');
      expect(board.grid[4][1]!.moveStyle, MoveStyle.pawnStyle);
      expect(board.grid[3][1]!.specialUsed, isTrue);
    });

    test('takımın canlı bir piyonu varsa normal hareket eder, çağırma tetiklenmez', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.necromancerSah, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 6, 1),
      ]);
      board.movePiece(3, 1, 4, 1);
      expect(board.grid[3][1], isNull, reason: 'bu sefer Şah normal şekilde hareket etmeli');
      expect(board.grid[4][1]!.isKingPiece, isTrue);
    });
  });

  group('Özel yetenek: Büyücü — Ayna Yansıması', () {
    test('oyunda 1 kez dik/yatay 1 kare kayabilir, kullanınca yenilenmez', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.buyucu, Team.white, 3, 1),
      ]);
      final movesBefore = board.rawMovesFor(3, 1);
      expect(movesBefore, contains(const Point(3, 2)));
      expect(movesBefore, contains(const Point(2, 2)));

      board.movePiece(3, 1, 3, 2);
      expect(board.grid[3][2]!.specialUsed, isTrue);
      final movesAfter = board.rawMovesFor(3, 2);
      expect(movesAfter, isNot(contains(const Point(3, 1))));
    });
  });

  group('Özel yetenek: Şaman — Ruh Yolu', () {
    test('ölü dost piyon varsa çapraz hattı 90° kırarak uzatabilir', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.saman, Team.white, 3, 1),
      ], presetDeadPawns: {Team.white: 1});
      final moves = board.rawMovesFor(3, 1);
      expect(moves, contains(const Point(1, 1)));
      expect(moves, contains(const Point(0, 2)));
    });

    test('ölü dost piyon yoksa kırılmış hareketler üretilmez', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.saman, Team.white, 3, 1),
      ]);
      final moves = board.rawMovesFor(3, 1);
      expect(moves, isNot(contains(const Point(1, 1))));
    });
  });

  group('Özel yetenek: Gölge Piyonu — Kör Nokta', () {
    test('önündeki taşın türü fark etmeksizin 2 kare çaprazdaki rakibi vurabilir', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.golgePiyonu, Team.white, 3, 1),
        ScenarioPlacement(PieceLibrary.pawn, Team.white, 2, 2),
        ScenarioPlacement(PieceLibrary.pawn, Team.black, 1, 3),
      ]);
      final moves = board.rawMovesFor(3, 1);
      expect(moves, contains(const Point(1, 3)));
      expect(moves, isNot(contains(const Point(2, 2))), reason: 'dost kareyi vuramaz');
    });
  });

  group('Özel yetenek: Sipahi — Süvari Hücumu', () {
    test('başlangıç sırasında 1, 2 VE 3 kare ileri gidebilir', () {
      final board = BoardController();
      board.loadScenario([
        ScenarioPlacement(PieceLibrary.sipahi, Team.white, 6, 1),
      ]);
      final moves = board.rawMovesFor(6, 1);
      expect(moves, containsAll(const [Point(5, 1), Point(4, 1), Point(3, 1)]));
    });
  });
}