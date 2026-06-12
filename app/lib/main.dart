import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/overlays/game_over_overlay.dart';
import 'game/overlays/main_menu_overlay.dart';
import 'game/overlays/pause_overlay.dart';
import 'game/overlays/settings_overlay.dart';
import 'game/fitit_game.dart';

void main() {
  runApp(
    GameWidget<FititGame>.controlled(
      gameFactory: FititGame.new,
      overlayBuilderMap: {
        'MainMenu': (_, game) => MainMenuOverlay(game: game),
        'GameOver': (_, game) => GameOverOverlay(game: game),
        'Pause': (_, game) => PauseOverlay(game: game),
        'Settings': (_, game) => SettingsOverlay(game: game),
      },
      initialActiveOverlays: const ['MainMenu'],
    ),
  );
}
