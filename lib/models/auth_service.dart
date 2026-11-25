import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication'ı sarmalayan basit servis.
///
/// Varsayılan akış: oyuncu hiçbir şey yapmadan otomatik olarak ANONİM bir
/// hesaba sahip olur (bkz. [ensureSignedIn]) — böylece hiç kayıt formu
/// doldurmadan hemen oynayabilir. İstersen bu anonim hesabı gerçek bir
/// e-posta/şifreyle "bağlayıp" (bkz. [linkEmailPassword]) telefon
/// değiştirince de aynı hesaba erişebilir hale getirebilirsin.
class AuthService extends ChangeNotifier {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  User? get currentUser => FirebaseAuth.instance.currentUser;
  String? get uid => currentUser?.uid;
  bool get isSignedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// Uygulama açılışında çağrılır: kayıtlı bir oturum varsa onu kullanır,
  /// yoksa otomatik olarak anonim bir hesap oluşturur. Bu, `main.dart`
  /// içinde `runApp`'ten ÖNCE çağrılmalı ki hiçbir ekran uid'siz kalmasın.
  Future<void> ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  /// Anonim hesabı gerçek bir e-posta/şifreyle ilişkilendirir. Böylece
  /// oyuncu telefonunu değiştirse bile aynı hesaba giriş yapıp verilerine
  /// (altın, kartlar, kupa vb.) ulaşabilir. Hata yoksa null döner.
  Future<String?> linkEmailPassword(String email, String password) async {
    final user = currentUser;
    if (user == null) return 'Oturum bulunamadı';
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.linkWithCredential(credential);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    }
  }

  /// Daha önce e-posta/şifre ile bağlanmış bir hesaba (ör. başka bir
  /// cihazdan) giriş yapmak için. Hata yoksa null döner.
  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
