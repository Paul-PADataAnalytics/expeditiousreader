import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';
import '../utils/text_processor.dart';

class ReadingThemeChips extends StatelessWidget {
  final SettingsProvider provider;

  const ReadingThemeChips({super.key, required this.provider});

  static const Color sepiaBackground = Color(0xFFF4ECD8);
  static const Color sepiaText = Color(0xFF5B4636);

  @override
  Widget build(BuildContext context) {
    final bg = provider.settings.backgroundColor;
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Light'),
          selected: bg == Colors.white,
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
          selected: bg == Colors.black,
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
          selected: bg == sepiaBackground,
          onSelected: (selected) {
            if (selected) {
              provider.updateColors(
                backgroundColor: sepiaBackground,
                textColor: sepiaText,
              );
            }
          },
        ),
      ],
    );
  }
}

Future<void> showChaptersModalDialog({
  required BuildContext context,
  required List<ChapterInfo> chapters,
  required int currentChapter,
  required int totalWords,
  required ValueChanged<ChapterInfo> onChapterSelected,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Chapters & Sections'),
      content: SizedBox(
        width: 420,
        height: 440,
        child: ListView.separated(
          itemCount: chapters.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final ch = chapters[index];
            final isCurrent = ch.number == currentChapter;
            final pct = totalWords > 0
                ? ((ch.wordIndex / totalWords) * 100).toStringAsFixed(0)
                : '0';
            return ListTile(
              selected: isCurrent,
              leading: CircleAvatar(
                radius: 14,
                child: Text('${ch.number}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(
                ch.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: Text('$pct%', style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                onChapterSelected(ch);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
