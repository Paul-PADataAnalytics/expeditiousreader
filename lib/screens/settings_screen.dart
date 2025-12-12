// filepath: /home/paul/Documents/projects/expeditiousreader/lib/screens/settings_screen.dart
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
          // APPEARANCE SECTION
          _buildSectionHeader('Appearance'),
          Consumer<SettingsProvider>(
            builder: (context, provider, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubsectionHeader(context, 'App Theme'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 18),
                        label: Text('Light'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 18),
                        label: Text('Dark'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 18),
                        label: Text('Auto'),
                      ),
                    ],
                    selected: {provider.settings.themeMode},
                    onSelectionChanged: (Set<ThemeMode> selected) {
                      provider.updateThemeMode(selected.first);
                    },
                  ),
                ),
                _buildHintText(context, _getThemeModeName(provider.settings.themeMode)),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          const Divider(height: 32),

          // SPEED READING SECTION
          _buildSectionHeader('Speed Reading'),
          Consumer<SettingsProvider>(
            builder: (context, provider, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                
                const Divider(indent: 16, endIndent: 16, height: 32),
                
                _buildSubsectionHeader(context, 'Reading Theme'),
                _buildHintText(context, 'Choose the color scheme for speed reading mode'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Light'),
                        selected: provider.settings.backgroundColor == Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            provider.updateColors(
                              backgroundColor: Colors.white,
                              textColor: Colors.black,
                            );
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Dark'),
                        selected: provider.settings.backgroundColor == Colors.black,
                        onSelected: (selected) {
                          if (selected) {
                            provider.updateColors(
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                            );
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Sepia'),
                        selected: provider.settings.backgroundColor == const Color(0xFFF4ECD8),
                        onSelected: (selected) {
                          if (selected) {
                            provider.updateColors(
                              backgroundColor: const Color(0xFFF4ECD8),
                              textColor: const Color(0xFF5B4636),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const Divider(height: 32),

          // TRADITIONAL READING SECTION
          _buildSectionHeader('Traditional Reading'),
          Consumer<SettingsProvider>(
            builder: (context, provider, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                
                const Divider(indent: 16, endIndent: 16, height: 32),
                
                _buildSubsectionHeader(context, 'Reading Theme'),
                _buildHintText(context, 'Choose the color scheme for traditional reading mode'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Light'),
                        selected: provider.settings.backgroundColor == Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            provider.updateColors(
                              backgroundColor: Colors.white,
                              textColor: Colors.black,
                            );
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Dark'),
                        selected: provider.settings.backgroundColor == Colors.black,
                        onSelected: (selected) {
                          if (selected) {
                            provider.updateColors(
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                            );
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Sepia'),
                        selected: provider.settings.backgroundColor == const Color(0xFFF4ECD8),
                        onSelected: (selected) {
                          if (selected) {
                            provider.updateColors(
                              backgroundColor: const Color(0xFFF4ECD8),
                              textColor: const Color(0xFF5B4636),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const Divider(height: 32),

          // ABOUT SECTION
          _buildSectionHeader('About'),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info_outline),
          ),
          const ListTile(
            title: Text('Expeditious Reader'),
            subtitle: Text('A speed reading and ebook management application'),
            leading: Icon(Icons.book),
          ),

          const Divider(height: 32),

          // RESET BUTTON
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<SettingsProvider>(
              builder: (context, provider, child) => OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset All Settings to Default'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
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
                        FilledButton(
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubsectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHintText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system theme settings';
    }
  }
}
