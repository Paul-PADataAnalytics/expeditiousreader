import 'package:flutter/material.dart';

class ReadingSettings {
  final int wordsPerMinute; // Speed reading WPM
  final double speedReaderFontSize; // Font size for speed reader
  final double traditionalFontSize; // Font size for traditional reader
  final String fontFamily;
  final Color backgroundColor;
  final Color textColor;
  final bool pauseOnLongWords;
  final int longWordThreshold; // Number of characters to consider a word "long"
  final int longWordPauseMultiplier; // Multiplier for pause duration
  final bool pauseOnSentenceEnd; // Pause longer at sentence endings
  final int wordsPerPage; // For traditional reading mode (deprecated, use dynamic layout)
  final int numberOfColumns; // Number of columns for traditional reading
  final double columnGap; // Gap between columns in pixels
  final double lineHeight; // Line height multiplier
  final ThemeMode themeMode; // Light, dark, or system theme

  ReadingSettings({
    this.wordsPerMinute = 300,
    this.speedReaderFontSize = 32.0,
    this.traditionalFontSize = 18.0,
    this.fontFamily = 'Roboto',
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.pauseOnLongWords = true,
    this.longWordThreshold = 10,
    this.longWordPauseMultiplier = 2,
    this.pauseOnSentenceEnd = true,
    this.wordsPerPage = 300,
    this.numberOfColumns = 2,
    this.columnGap = 32.0,
    this.lineHeight = 1.6,
    this.themeMode = ThemeMode.system,
  });

  factory ReadingSettings.fromJson(Map<String, dynamic> json) {
    // For backwards compatibility, if old 'fontSize' exists, use it for both
    final oldFontSize = (json['fontSize'] as num?)?.toDouble();
    
    // Parse theme mode
    ThemeMode themeMode = ThemeMode.system;
    if (json['themeMode'] != null) {
      final themeModeString = json['themeMode'] as String;
      themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }
    
    return ReadingSettings(
      wordsPerMinute: json['wordsPerMinute'] as int? ?? 300,
      speedReaderFontSize: (json['speedReaderFontSize'] as num?)?.toDouble() ?? oldFontSize ?? 32.0,
      traditionalFontSize: (json['traditionalFontSize'] as num?)?.toDouble() ?? oldFontSize ?? 18.0,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFFFFFFFF),
      textColor: Color(json['textColor'] as int? ?? 0xFF000000),
      pauseOnLongWords: json['pauseOnLongWords'] as bool? ?? true,
      longWordThreshold: json['longWordThreshold'] as int? ?? 10,
      longWordPauseMultiplier: json['longWordPauseMultiplier'] as int? ?? 2,
      pauseOnSentenceEnd: json['pauseOnSentenceEnd'] as bool? ?? true,
      wordsPerPage: json['wordsPerPage'] as int? ?? 300,
      numberOfColumns: json['numberOfColumns'] as int? ?? 2,
      columnGap: (json['columnGap'] as num?)?.toDouble() ?? 32.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.6,
      themeMode: themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wordsPerMinute': wordsPerMinute,
      'speedReaderFontSize': speedReaderFontSize,
      'traditionalFontSize': traditionalFontSize,
      'fontFamily': fontFamily,
      'backgroundColor': backgroundColor.value,
      'textColor': textColor.value,
      'pauseOnLongWords': pauseOnLongWords,
      'longWordThreshold': longWordThreshold,
      'longWordPauseMultiplier': longWordPauseMultiplier,
      'pauseOnSentenceEnd': pauseOnSentenceEnd,
      'wordsPerPage': wordsPerPage,
      'numberOfColumns': numberOfColumns,
      'columnGap': columnGap,
      'lineHeight': lineHeight,
      'themeMode': themeMode.toString(),
    };
  }

  ReadingSettings copyWith({
    int? wordsPerMinute,
    double? speedReaderFontSize,
    double? traditionalFontSize,
    String? fontFamily,
    Color? backgroundColor,
    Color? textColor,
    bool? pauseOnLongWords,
    int? longWordThreshold,
    int? longWordPauseMultiplier,
    bool? pauseOnSentenceEnd,
    int? wordsPerPage,
    int? numberOfColumns,
    double? columnGap,
    double? lineHeight,
    ThemeMode? themeMode,
  }) {
    return ReadingSettings(
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      speedReaderFontSize: speedReaderFontSize ?? this.speedReaderFontSize,
      traditionalFontSize: traditionalFontSize ?? this.traditionalFontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      pauseOnLongWords: pauseOnLongWords ?? this.pauseOnLongWords,
      longWordThreshold: longWordThreshold ?? this.longWordThreshold,
      longWordPauseMultiplier: longWordPauseMultiplier ?? this.longWordPauseMultiplier,
      pauseOnSentenceEnd: pauseOnSentenceEnd ?? this.pauseOnSentenceEnd,
      wordsPerPage: wordsPerPage ?? this.wordsPerPage,
      numberOfColumns: numberOfColumns ?? this.numberOfColumns,
      columnGap: columnGap ?? this.columnGap,
      lineHeight: lineHeight ?? this.lineHeight,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
