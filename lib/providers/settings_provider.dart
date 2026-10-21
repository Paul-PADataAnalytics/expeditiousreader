import 'package:flutter/material.dart';
import '../models/reading_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  ReadingSettings _settings = const ReadingSettings();

  ReadingSettings get settings => _settings;

  Future<void> loadSettings() async {
    _settings = await _settingsService.loadSettings();
    notifyListeners();
  }

  Future<void> updateSettings(ReadingSettings newSettings) async {
    _settings = newSettings;
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateWPM(int wpm) async {
    await updateSettings(_settings.copyWith(wordsPerMinute: wpm));
  }

  Future<void> updateSpeedReaderFontSize(double size) async {
    await updateSettings(_settings.copyWith(speedReaderFontSize: size));
  }

  Future<void> updateTraditionalFontSize(double size) async {
    await updateSettings(_settings.copyWith(traditionalFontSize: size));
  }

  Future<void> updateRespectFormatting(bool value) async {
    await updateSettings(_settings.copyWith(respectFormatting: value));
  }

  Future<void> updateColors({
    required Color backgroundColor,
    required Color textColor,
  }) async {
    await updateSettings(
      _settings.copyWith(
        backgroundColor: backgroundColor,
        textColor: textColor,
      ),
    );
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    await updateSettings(_settings.copyWith(themeMode: themeMode));
  }
}
