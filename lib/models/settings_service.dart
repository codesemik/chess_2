import 'package:flutter/foundation.dart';

/// Uygulama ayarlarını (ses aç/kapa, ses seviyesi) tutan servis.
/// Not: Bu projede henüz gerçek bir ses/müzik motoru bağlı değil;
/// bu servis arayüz durumunu (UI state) tutar ve ileride bir ses
/// paketine (ör. audioplayers) bağlanmaya hazır şekilde tasarlanmıştır.
class SettingsService extends ChangeNotifier {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  bool musicEnabled = true;
  bool sfxEnabled = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;

  void toggleMusic(bool value) {
    musicEnabled = value;
    notifyListeners();
  }

  void toggleSfx(bool value) {
    sfxEnabled = value;
    notifyListeners();
  }

  void setMusicVolume(double value) {
    musicVolume = value;
    notifyListeners();
  }

  void setSfxVolume(double value) {
    sfxVolume = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // BULUT SENKRONİZASYONU (Firestore) — bkz. CloudSyncService
  // ---------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'musicEnabled': musicEnabled,
        'sfxEnabled': sfxEnabled,
        'musicVolume': musicVolume,
        'sfxVolume': sfxVolume,
      };

  void restoreFromJson(Map<String, dynamic> json) {
    musicEnabled = json['musicEnabled'] as bool? ?? musicEnabled;
    sfxEnabled = json['sfxEnabled'] as bool? ?? sfxEnabled;
    final mv = json['musicVolume'];
    if (mv is num) musicVolume = mv.toDouble();
    final sv = json['sfxVolume'];
    if (sv is num) sfxVolume = sv.toDouble();
  }
}
