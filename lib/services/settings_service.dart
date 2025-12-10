import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_settings.dart';

class SettingsService {
  static const String _settingsKey = 'reading_settings';

  /// Load reading settings
  Future<ReadingSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      
      if (jsonString == null) {
        return ReadingSettings();
      }
      
      final json = jsonDecode(jsonString);
      return ReadingSettings.fromJson(json);
    } catch (e) {
      print('Error loading settings: $e');
      return ReadingSettings();
    }
  }

  /// Save reading settings
  Future<void> saveSettings(ReadingSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, jsonString);
    } catch (e) {
      print('Error saving settings: $e');
      throw Exception('Failed to save settings');
    }
  }
}
