import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:durus/app.dart';
import 'package:durus/core/config.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/theme/themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        themeKeyProvider.overrideWith(
          (ref) => normalizeThemeKey(prefs.getString('theme_key')),
        ),
      ],
      child: const DurusApp(),
    ),
  );
}