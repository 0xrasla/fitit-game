import 'package:flutter/material.dart';

class GameColor {
  final String name;
  final Color color;
  final String displayLabel;

  const GameColor({
    required this.name,
    required this.color,
    required this.displayLabel,
  });
}

final List<GameColor> gameColors = [
  GameColor(name: 'red', color: Colors.redAccent, displayLabel: 'RED'),
  GameColor(name: 'blue', color: Colors.blueAccent, displayLabel: 'BLUE'),
  GameColor(name: 'green', color: Colors.greenAccent, displayLabel: 'GREEN'),
  GameColor(name: 'yellow', color: Colors.amberAccent, displayLabel: 'YELLOW'),
  GameColor(name: 'purple', color: Colors.deepPurpleAccent, displayLabel: 'PURPLE'),
  GameColor(name: 'orange', color: Colors.orangeAccent, displayLabel: 'ORANGE'),
];
