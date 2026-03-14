import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Verify Firestore connectivity with a small test write.
  await FirestoreService.instance.writeConnectionTest();

  // Seed dummy equipment data on first launch.
  await FirestoreService.instance.seedDummyEquipment();

  runApp(const AgroShareApp());
}
