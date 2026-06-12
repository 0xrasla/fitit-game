import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../fitit_game.dart';

class MainMenuOverlay extends StatelessWidget {
  final FititGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/fitit_logo.png', width: 90, height: 90),
                const SizedBox(height: 6),
                Text(
                  'FITIT',
                  style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fit it, Every Second Counts',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 3,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: () => game.startGame(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 72, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    'PLAY',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => game.showSettings(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 56, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    'SETTINGS',
                    style: GoogleFonts.orbitron(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 5,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text(
                    'EXIT',
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
