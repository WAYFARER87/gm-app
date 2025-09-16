import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/radio/radio_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final radioController = RadioController();
  runApp(
    ChangeNotifierProvider.value(
      value: radioController,
      child: const MyApp(),
    ),
  );
}
