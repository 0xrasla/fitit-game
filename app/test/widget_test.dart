import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/game/fitit_game.dart';

Widget buildGame() {
  return GameWidget<FititGame>.controlled(
    gameFactory: FititGame.new,
    overlayBuilderMap: {
      'MainMenu': (_, game) => const SizedBox.shrink(),
      'GameOver': (_, game) => const SizedBox.shrink(),
      'Pause': (_, game) => const SizedBox.shrink(),
    },
    initialActiveOverlays: const ['MainMenu'],
  );
}

void main() {
  testWidgets('Game loads without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildGame());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
