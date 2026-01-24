import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBgV_TmoKG-2SP7pLd1kzpDRaLKOGOjvw',
    appId: '1:593978924948:android:3a7573e465709fd84d3981',
    messagingSenderId: '593978924948',
    projectId: 'ridesharing-98e9f',
    storageBucket: 'ridesharing-98e9f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDy5Q_bYiLAcOcAj30KkGisMEQ1Ni0_tTk',
    appId: '1:593978924948:ios:91c2a6adb4a51ec44d3981',
    messagingSenderId: '593978924948',
    projectId: 'ridesharing-98e9f',
    storageBucket: 'ridesharing-98e9f.firebasestorage.app',
    iosClientId: '593978924948-p21tmsn1rs54a6h1tnkvv923k2gl4h7s.apps.googleusercontent.com',
    iosBundleId: 'com.app.ridesharing',
  );

}