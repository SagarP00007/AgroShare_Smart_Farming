import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'l10n/locale_provider.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try initializing Firebase safely so initialization errors do not block runApp.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // ignore: avoid_print
    print('Firebase initialization warning: $e');
  }

  // Load saved locale and translations for multilingual support safely.
  final localeProvider = await LocaleProvider.create();

  // Run app immediately so screen mounts without waiting for network IO.
  runApp(AgroShareApp(localeProvider: localeProvider));

  // Perform Firestore connectivity check and dummy data seeding asynchronously in background.
  _runBackgroundTasks();
}

void _runBackgroundTasks() async {
  try {
    await FirestoreService.instance.writeConnectionTest();
    await FirestoreService.instance.seedDummyEquipment();
  } catch (e) {
    // ignore: avoid_print
    print('Background Firestore setup skipped or failed: $e');
  }
}
