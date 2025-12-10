import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/reading_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Speed Reading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, provider, child) => Column(
              children: [
                ListTile(
                  title: const Text('Font Size'),
                  subtitle: Text('${provider.settings.speedReaderFontSize.toStringAsFixed(0)} pt'),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: provider.settings.speedReaderFontSize,
                      min: 16,
                      max: 72,
                      divisions: 28,
                      label: provider.settings.speedReaderFontSize.toStringAsFixed(0),
                      onChanged: (value) {
                        provider.updateSpeedReaderFontSize(value);
                      },
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Words Per Minute'),
                  subtitle: Text('${provider.settings.wordsPerMinute} WPM'),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: provider.settings.wordsPerMinute.toDouble(),
                      min: 100,
                      max: 1000,
                      divisions: 90,
                      label: '${provider.settings.wordsPerMinute} WPM',
                      onChanged: (value) {
                        provider.updateWPM(value.toInt());
                      },
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Pause on Long Words'),
                  subtitle: const Text('Pause longer on words with many characters'),
                  value: provider.settings.pauseOnLongWords,
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(pauseOnLongWords: value),
                    );
                  },
                ),
                if (provider.settings.pauseOnLongWords)
                  ListTile(
                    title: const Text('Long Word Threshold'),
                    subtitle: Text(
                      '${provider.settings.longWordThreshold} characters',
                    ),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: provider.settings.longWordThreshold.toDouble(),
                        min: 5,
                        max: 20,
                        divisions: 15,
                        label: '${provider.settings.longWordThreshold}',
                        onChanged: (value) {
                          provider.updateSettings(
                            provider.settings.copyWith(
                              longWordThreshold: value.toInt(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                SwitchListTile(
                  title: const Text('Sentence End Pause'),
                  subtitle: const Text('Double wait on the first word of a new sentence'),
                  value: provider.settings.pauseOnSentenceEnd,
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(pauseOnSentenceEnd: value),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Traditional Reading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, provider, child) => Column(
              children: [
                ListTile(
                  title: const Text('Font Size'),
                  subtitle: Text('${provider.settings.traditionalFontSize.toStringAsFixed(0)} pt'),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: provider.settings.traditionalFontSize,
                      min: 12,
                      max: 72,
                      divisions: 60,
                      label: provider.settings.traditionalFontSize.toStringAsFixed(0),
                      onChanged: (value) {
                        provider.updateTraditionalFontSize(value);
                      },
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Words Per Page'),
                  subtitle: Text('${provider.settings.wordsPerPage} words'),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: provider.settings.wordsPerPage.toDouble(),
                      min: 100,
                      max: 500,
                      divisions: 40,
                      label: '${provider.settings.wordsPerPage}',
                      onChanged: (value) {
                        provider.updateSettings(
                          provider.settings.copyWith(wordsPerPage: value.toInt()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, provider, child) => Column(
              children: [
                ListTile(
                  title: const Text('Light Theme'),
                  leading: Radio<String>(
                    value: 'light',
                    groupValue: _getTheme(provider),
                    onChanged: (value) {
                      provider.updateColors(
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                      );
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Dark Theme'),
                  leading: Radio<String>(
                    value: 'dark',
                    groupValue: _getTheme(provider),
                    onChanged: (value) {
                      provider.updateColors(
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                      );
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Sepia Theme'),
                  leading: Radio<String>(
                    value: 'sepia',
                    groupValue: _getTheme(provider),
                    onChanged: (value) {
                      provider.updateColors(
                        backgroundColor: const Color(0xFFF4ECD8),
                        textColor: const Color(0xFF5B4636),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('Expeditious Reader'),
            subtitle: Text('A speed reading and ebook management application'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<SettingsProvider>(
              builder: (context, provider, child) => ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Settings to Default'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset Settings'),
                      content: const Text(
                        'Are you sure you want to reset all settings to their default values?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await provider.updateSettings(ReadingSettings());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings reset to defaults'),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTheme(SettingsProvider provider) {
    if (provider.settings.backgroundColor == Colors.white) {
      return 'light';
    } else if (provider.settings.backgroundColor == Colors.black) {
      return 'dark';
    } else {
      return 'sepia';
    }
  }
}
