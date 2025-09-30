from pathlib import Path
path = Path(r"b:\\WordChain\\wordchain\\lib\\src\\features\\menu\\menu_screen.dart")
text = path.read_text()
if "hooks_riverpod" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';\n\n",
        "import 'package:flutter/material.dart';\nimport 'package:hooks_riverpod/hooks_riverpod.dart';\n\nimport 'package:wordchain/main.dart';\n\nimport '../../core/sound_manager.dart';\n\n",
        1,
    )
text = text.replace(
    "class MenuScreen extends StatefulWidget {",
    "class MenuScreen extends ConsumerStatefulWidget {",
    1,
)
text = text.replace(
    "class _MenuScreenState extends State<MenuScreen>\n    with SingleTickerProviderStateMixin {",
    "class _MenuScreenState extends ConsumerState<MenuScreen>\n    with SingleTickerProviderStateMixin, RouteAware {",
    1,
)
text = text.replace(
    "  @override\n  void initState() {",
    "  bool _isRouteSubscribed = false;\n  bool _menuMusicPlaying = false;\n\n  @override\n  void initState() {",
    1,
)
if "void dispose()" in text and "routeObserver.unsubscribe" not in text:
    text = text.replace(
        "  @override\n  void dispose() {\n    _ctrl.dispose();\n    super.dispose();\n  }",
        "  @override\n  void dispose() {\n    if (_isRouteSubscribed) {\n      routeObserver.unsubscribe(this);\n    }\n    _stopMenuMusic();\n    _ctrl.dispose();\n    super.dispose();\n  }",
        1,
    )
text = text.replace(
    "  @override\n  Widget build(BuildContext context) {",
    "  @override\n  void didChangeDependencies() {\n    super.didChangeDependencies();\n    final route = ModalRoute.of(context);
    if (!_isRouteSubscribed && route is PageRoute) {
      routeObserver.subscribe(this, route);
      _isRouteSubscribed = true;
    }
  }

  @override
  void didPush() {
    _playMenuMusic();
  }

  @override
  void didPopNext() {
    _playMenuMusic();
  }

  @override
  void didPushNext() {
    _stopMenuMusic();
  }

  @override
  void didPop() {
    _stopMenuMusic();
  }

  Future<void> _playMenuMusic() async {
    if (_menuMusicPlaying) return;
    _menuMusicPlaying = true;
    await ref.read(soundManagerProvider).playMenuMusic();
  }

  Future<void> _stopMenuMusic() async {
    if (!_menuMusicPlaying) return;
    _menuMusicPlaying = false;
    await ref.read(soundManagerProvider).stopMenuMusic();
  }

  @override
  Widget build(BuildContext context) {",
    1,
)
path.write_text(text)
