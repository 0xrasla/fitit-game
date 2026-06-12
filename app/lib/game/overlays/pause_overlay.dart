import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../fitit_game.dart';

class PauseOverlay extends StatelessWidget {
  final FititGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withAlpha(220),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PAUSED',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => game.resume(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Text(
                  'RESUME',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => game.goToMenu(),
                child: Text(
                  'QUIT',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 3,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
