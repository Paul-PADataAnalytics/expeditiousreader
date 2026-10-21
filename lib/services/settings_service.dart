import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_settings.dart';

class SettingsService {
  static const String _settingsKey = 'reading_settings';

  Future<ReadingSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString == null) {
        return const ReadingSettings();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ReadingSettings.fromJson(json);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return const ReadingSettings();
    }
  }

  Future<void> saveSettings(ReadingSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving settings: $e');
      throw Exception('Failed to save settings');
    }
  }
}
