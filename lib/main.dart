import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'l10n/localization_service.dart';
import 'models/auth_service.dart';
import 'models/cloud_sync_service.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Oyuncu hiçbir şey yapmadan otomatik olarak (anonim) bir hesaba sahip
    // olur; verisi bu hesaba bağlı olarak buluta kaydedilir.
    await AuthService.instance.ensureSignedIn();
    // Buluttaki veriyi (varsa) yerel servislere yükler ve bundan sonraki
    // her değişikliği otomatik olarak buluta yazmaya başlar.
    await CloudSyncService.instance.loadAndAttach();
  } catch (e) {
    // Firebase'e ulaşılamadıysa (ör. ilk açılışta internet yok) uygulama
    // yine de yerel varsayılanlarla açılır; bağlantı gelince bir sonraki
    // değişiklikte otomatik senkronize olmaya çalışılır.
    debugPrint('Firebase başlatılamadı, çevrimdışı modda devam ediliyor: $e');
  }

  runApp(const Chess2App());
}

class Chess2App extends StatelessWidget {
  const Chess2App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dil değiştiğinde tüm uygulamanın (başlık dahil) yeniden çizilmesi için
    // en üst seviyede LocalizationService'i dinliyoruz.
    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: loc('app_title'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          home: const MainShell(),
        );
      },
    );
  }
}
