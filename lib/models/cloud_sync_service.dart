import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'collection_service.dart';
import 'card_level_service.dart';
import 'formation_service.dart';
import 'profile_service.dart';
import 'settings_service.dart';
import '../l10n/localization_service.dart';

/// Oyuncu verisini (altın, kartlar, seviyeler, diziliş, profil, ayarlar,
/// dil) Firestore'daki `users/{uid}` dokümanıyla senkronize eder.
///
/// Açılışta [loadAndAttach] bir kez çağrılır: önce buluttaki veri yerel
/// servislere yüklenir, sonra bu servislerden HERHANGİ biri değişince
/// (kısa bir gecikmeyle/"debounce") otomatik olarak buluta yazılır.
/// Böylece ekranlarda "kaydet" butonuna hiç gerek kalmaz.
class CloudSyncService {
  CloudSyncService._internal();
  static final CloudSyncService instance = CloudSyncService._internal();

  Timer? _saveTimer;
  bool _loading = false;
  bool _attached = false;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(AuthService.instance.uid);

  /// main.dart tarafından, [AuthService.ensureSignedIn] çağrıldıktan hemen
  /// sonra, `runApp`'ten önce çağrılmalıdır.
  Future<void> loadAndAttach() async {
    _loading = true;
    try {
      final snap = await _userDoc.get();
      if (snap.exists) {
        final data = snap.data();
        if (data != null) {
          _applyRemoteData(data);
        }
      } else {
        // İlk kez giriş yapıyor: mevcut varsayılan durumu hemen buluta yaz
        // ki `users/{uid}` dokümanı baştan itibaren var olsun.
        await _saveNow();
      }
    } catch (_) {
      // Bulut okunamadıysa (ör. ilk açılışta internet yok) yerel
      // varsayılanlarla devam edilir; bağlantı gelince otomatik senkronize
      // olur (Firestore'un çevrimdışı önbelleği sayesinde).
    }
    _loading = false;

    if (!_attached) {
      _attached = true;
      CollectionService.instance.addListener(_scheduleSave);
      CardLevelService.instance.addListener(_scheduleSave);
      FormationService.instance.addListener(_scheduleSave);
      ProfileService.instance.addListener(_scheduleSave);
      SettingsService.instance.addListener(_scheduleSave);
      LocalizationService.instance.addListener(_scheduleSave);
    }
  }

  void _applyRemoteData(Map<String, dynamic> data) {
    final collection = data['collection'];
    if (collection is Map) {
      CollectionService.instance.restoreFromJson(Map<String, dynamic>.from(collection));
    }
    final cardLevels = data['cardLevels'];
    if (cardLevels is Map) {
      CardLevelService.instance.restoreFromJson(Map<String, dynamic>.from(cardLevels));
    }
    final formation = data['formation'];
    if (formation is Map) {
      FormationService.instance.restoreFromJson(Map<String, dynamic>.from(formation));
    }
    final profile = data['profile'];
    if (profile is Map) {
      ProfileService.instance.restoreFromJson(Map<String, dynamic>.from(profile));
    }
    final settings = data['settings'];
    if (settings is Map) {
      SettingsService.instance.restoreFromJson(Map<String, dynamic>.from(settings));
    }
    final lang = data['language'];
    if (lang is String) {
      LocalizationService.instance.restoreLanguageCode(lang);
    }
  }

  void _scheduleSave() {
    if (_loading) return;
    if (AuthService.instance.uid == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  /// Herhangi bir yerden anında (gecikmesiz) kaydetmek gerekirse (ör. bir
  /// maç bitip kupa/altın güncellendiğinde) bu doğrudan çağrılabilir.
  Future<void> saveNow() => _saveNow();

  Future<void> _saveNow() async {
    if (AuthService.instance.uid == null) return;
    try {
      await _userDoc.set({
        'collection': CollectionService.instance.toJson(),
        'cardLevels': CardLevelService.instance.toJson(),
        'formation': FormationService.instance.toJson(),
        'profile': ProfileService.instance.toJson(),
        'settings': SettingsService.instance.toJson(),
        'language': LocalizationService.instance.language.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Çevrimdışıysa Firestore SDK'sı yazmayı yerel önbelleğe alır ve
      // bağlantı gelince otomatik olarak buluta gönderir.
    }
  }
}
