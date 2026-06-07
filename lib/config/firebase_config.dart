import 'package:firebase_core/firebase_core.dart';

// Firebase initialization
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'YOUR_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId: 'shougaku-kore-doutoku',
      storageBucket: 'shougaku-kore-doutoku.appspot.com',
    ),
  );
}
