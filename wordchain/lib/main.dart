import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'src/core/app_theme.dart';
import 'src/features/menu/menu_screen.dart';
import 'src/features/game/game_screen.dart';
import 'src/features/gallery/gallery_screen.dart';
import 'src/features/achievements/achievements_screen.dart';
import 'src/features/stats/stats_screen.dart';
import 'src/features/settings/settings_screen.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: WordChainApp()));
}

class WordChainApp extends StatelessWidget {
  const WordChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordChain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      navigatorObservers: [routeObserver],
      routes: {
        '/': (_) => const MenuScreen(),
        '/game': (_) => const GameScreen(),
        '/gallery': (_) => const GalleryScreen(),
        '/achievements': (_) => const AchievementsScreen(),
        '/stats': (_) => StatsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
