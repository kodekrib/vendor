import 'package:flutter/material.dart';

import 'app.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OnboarderApp.applyBranding(await SettingsService.fetchSettings());
  runApp(const OnboarderApp());
}
