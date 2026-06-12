import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../audio/audio_manager.dart';
import '../../persistence/settings_store.dart';
import '../../theme/app_theme.dart';
import '../fitit_game.dart';

class SettingsOverlay extends StatefulWidget {
  final FititGame game;
  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  bool _sfx = true;
  bool _music = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sfx = await SettingsStore.isSfxEnabled();
    final music = await SettingsStore.isMusicEnabled();
    if (mounted) {
      setState(() {
        _sfx = sfx;
        _music = music;
        _loading = false;
      });
    }
  }

  Future<void> _toggleSfx(bool v) async {
    setState(() => _sfx = v);
    AudioManager.sfxEnabled = v;
    await SettingsStore.setSfxEnabled(v);
  }

  Future<void> _toggleMusic(bool v) async {
    setState(() => _music = v);
    AudioManager.musicEnabled = v;
    await SettingsStore.setMusicEnabled(v);
    if (v) {
      AudioManager.playBgm();
    } else {
      AudioManager.stopBgm();
    }
  }

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
          child: _loading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SETTINGS',
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildRow('Sound Effects', _sfx, _toggleSfx),
                    const SizedBox(height: 16),
                    _buildRow('Music', _music, _toggleMusic),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => widget.game.hideSettings(),
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
                        'DONE',
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.success,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
