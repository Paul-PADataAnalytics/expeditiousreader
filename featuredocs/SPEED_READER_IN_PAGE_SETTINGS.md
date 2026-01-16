# Speed Reader In-Page Settings

## Overview
This document describes the implementation of color/theme settings in the speed reader mode's in-page settings dialog. Users can now change the speed reader theme while actively reading, providing instant visual feedback without leaving the reading experience.

## Feature Description

### Location
The color/theme settings are accessible in the **Speed Reader Screen** via the settings icon (⚙️) in the app bar, which opens an in-page dialog.

### Available Themes
Three color themes are available in the in-page settings:

1. **Light** 
   - Background: White
   - Text: Black
   - Best for well-lit environments

2. **Dark**
   - Background: Black
   - Text: White  
   - Best for low-light reading and reducing eye strain

3. **Sepia**
   - Background: Warm beige (#F4ECD8)
   - Text: Dark brown (#5B4636)
   - Best for extended reading sessions, paper-like appearance

## Implementation Details

### File Modified
- `lib/screens/speed_reader_screen.dart`

### Changes Made

#### 1. Enhanced Settings Dialog
The `_showSettingsDialog()` method was updated to include:
- **Font Size Control**: Slider (16-72pt)
- **Theme Selection**: ChoiceChip widgets for Light/Dark/Sepia

#### 2. Dialog Structure
```dart
void _showSettingsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reading Settings'),
      content: Consumer<SettingsProvider>(
        builder: (context, provider, child) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font Size section
            const Text('Font Size', style: ...),
            Slider(...),
            
            // Theme section
            const SizedBox(height: 16),
            const Text('Theme', style: ...),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                // Light, Dark, Sepia ChoiceChips
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
```

#### 3. Theme Detection Logic
Each ChoiceChip checks the current `backgroundColor` from settings:
- **Light**: `backgroundColor == Colors.white`
- **Dark**: `backgroundColor == Colors.black`
- **Sepia**: `backgroundColor == const Color(0xFFF4ECD8)`

#### 4. Theme Application
When a theme is selected, it calls:
```dart
provider.updateColors(
  backgroundColor: <theme_background>,
  textColor: <theme_text_color>,
);
```

This instantly updates:
- Background color of the screen
- Text color of the displayed word
- Progress text color
- WPM display color

### Integration with Settings Screen
The in-page dialog now offers the same theme options as the main Settings screen's "Speed Reader Theme" section, ensuring consistency across the app.

## User Experience

### Access Method
1. Open a book in Speed Reader mode
2. Tap the settings icon (⚙️) in the app bar
3. A dialog appears with font size and theme options

### Visual Feedback
- Selected theme is highlighted in the ChoiceChip
- Theme change applies **instantly** to the background and text
- No need to close the dialog to see the effect
- No app restart required

### Benefits
- **Instant Preview**: See changes immediately while reading
- **Convenient**: No need to navigate away from reading
- **Consistent**: Same themes as main settings
- **Intuitive**: Clear visual selection with modern UI

## Technical Notes

### State Management
- Uses `Consumer<SettingsProvider>` for reactive updates
- Settings persist via SharedPreferences
- Theme changes propagate instantly to all UI elements

### UI Components
- **ChoiceChip**: Modern Material 3 selection component
- **Wrap**: Responsive horizontal layout for theme chips
- **Consumer**: Ensures UI updates when settings change

### Performance
- Instant theme switching with no lag
- Minimal overhead (only updates colors)
- No need to rebuild entire screen

## Testing Checklist

✅ **Dialog Opens**: Settings icon opens dialog  
✅ **Font Size Works**: Slider adjusts text size  
✅ **Light Theme**: White background, black text  
✅ **Dark Theme**: Black background, white text  
✅ **Sepia Theme**: Beige background, brown text  
✅ **Instant Updates**: Changes apply immediately  
✅ **Selection State**: Correct chip is highlighted  
✅ **Persistence**: Theme persists after closing dialog  
✅ **Consistency**: Matches theme in main settings  

## Future Enhancements

Potential improvements for future versions:

1. **Custom Colors**: Allow users to create custom color schemes
2. **Preview Mode**: Show preview text in the dialog
3. **Preset Management**: Save and name custom themes
4. **More Themes**: Add additional built-in themes (e.g., High Contrast, Solarized)
5. **Theme Shortcuts**: Quick theme toggle button in reading interface

## Related Documentation

- `SPEED_READER_COLORS.md` - Initial speed reader color settings implementation
- `DARK_MODE_FEATURE.md` - App-wide dark mode implementation
- `SESSION_SUMMARY.md` - Complete session overview

## Conclusion

The in-page settings dialog now provides convenient access to speed reader theme settings, allowing users to adjust their reading environment on-the-fly without interrupting their flow. This completes the speed reader color settings feature, making theme customization available in both the main settings screen and the active reading interface.
