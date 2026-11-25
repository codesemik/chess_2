import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyDummyApiKeyForCI123456789',
      appId: '1:1234567890:android:dummyappid123',
      messagingSenderId: '1234567890',
      projectId: 'dummy-chess-project',
    );
  }
}