import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF5F5DC);
  static const textPrimary = Color(0xFF566573);
  static const textHint = Color(0xFF8E9EAB);
  static const success = Color(0xFF82E0AA);
  static const blue = Color(0xFFAED6F0);
  static const yellow = Color(0xFFF7DC6F);
  static const purple = Color(0xFFBB8FCE);
  static const pink = Color(0xFFFFB3B3);

  static const levelColors = [
    blue,
    success,
    yellow,
    purple,
    pink,
  ];
}

class AppTheme {
  static ThemeData get dark => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.background,
  );
}
