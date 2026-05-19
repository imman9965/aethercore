import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'di/injector.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Diagnostic: print which Firebase project the app is actually
  // connected to at runtime. Compare this to the project shown in your
  // Firebase Console URL — they must match exactly. If you've been
  // seeding documents in a different project, the app will never see
  // them no matter how correct the data looks.
  final FirebaseApp app = Firebase.app();
  debugPrint('[firebase] connected to projectId=${app.options.projectId}');
  debugPrint('[firebase] appId=${app.options.appId}');

  final Injector injector = Injector(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
  runApp(AetherApp(injector: injector));
}
