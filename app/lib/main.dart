import 'package:flutter/material.dart';
import 'app.dart';
import 'objectbox.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await ObjectBox.create();
  runApp(StudySyncApp(db: db));
}
