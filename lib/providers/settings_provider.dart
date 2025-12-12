import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/reading_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  ReadingSettings _settings = ReadingSettings();

  ReadingSettings get settings => _settings;

  /// Load settings from storage
  Future<void> loadSettings() async {
    _settings = await _settingsService.loadSettings();
    notifyListeners();
  }

  /// Update settings
  Future<void> updateSettings(ReadingSettings newSettings) async {
    _settings = newSettings;
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Update words per minute
  Future<void> updateWPM(int wpm) async {
    await updateSettings(_settings.copyWith(wordsPerMinute: wpm));
  }

  /// Update speed reader font size
  Future<void> updateSpeedReaderFontSize(double size) async {
    await updateSettings(_settings.copyWith(speedReaderFontSize: size));
  }

  /// Update traditional reader font size
  Future<void> updateTraditionalFontSize(double size) async {
    await updateSettings(_settings.copyWith(traditionalFontSize: size));
  }

  /// Update font size (deprecated - for backwards compatibility)
  @Deprecated('Use updateSpeedReaderFontSize or updateTraditionalFontSize')
  Future<void> updateFontSize(double size) async {
    // Update both for backwards compatibility
    await updateSettings(_settings.copyWith(
      speedReaderFontSize: size,
      traditionalFontSize: size,
    ));
  }

  /// Update colors
  Future<void> updateColors({
    required var backgroundColor,
    required var textColor,
  }) async {
    await updateSettings(_settings.copyWith(
      backgroundColor: backgroundColor,
      textColor: textColor,
    ));
  }

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    await updateSettings(_settings.copyWith(themeMode: themeMode));
  }
}
