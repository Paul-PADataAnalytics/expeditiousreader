# 🌙 Dark Mode Quick Start Guide

## How to Enable Dark Mode

### Step-by-Step Instructions

#### 1. Open Settings
- Launch Expeditious Reader
- Click on **Settings** in the bottom navigation bar

#### 2. Find Appearance Section
- Scroll to the top of Settings
- Look for the **"Appearance"** section header

#### 3. Select Your Theme
You'll see three options with icons:

```
┌─────────────────────────────────────────────────┐
│  Theme Mode                                     │
│  [Light] 🌞  [Dark] 🌙  [Auto] 🔄            │
└─────────────────────────────────────────────────┘
```

**Click one of the three buttons**:

- **Light** 🌞 - Always use light theme
- **Dark** 🌙 - Always use dark theme  
- **Auto** 🔄 - Follow your system settings

#### 4. Done!
The theme changes **instantly** - no need to restart the app!

---

## Theme Mode Details

### 🌞 Light Mode
**What it does**: Always shows light theme

**Use when**:
- You prefer bright UI
- Reading in well-lit environments
- You want consistent light appearance

**Result**:
- White/light backgrounds
- Dark text
- High contrast for daylight

---

### 🌙 Dark Mode
**What it does**: Always shows dark theme

**Use when**:
- Reading at night or in low light
- You prefer dark UIs
- Want to reduce eye strain
- Save battery (on OLED screens)

**Result**:
- Dark backgrounds
- Light text
- Easy on the eyes in low light

---

### 🔄 Auto Mode (System Default)
**What it does**: Follows your operating system's theme setting

**Use when**:
- You want automatic switching
- Your OS switches between light/dark throughout the day
- You prefer convenience

**Result**:
- Light theme when OS is in light mode
- Dark theme when OS is in dark mode
- Automatic updates when OS changes

---

## Visual Comparison

### Light Mode
```
┌─────────────────────────────────────┐
│ ☰  Library                       ⚙ │  ← Dark app bar
├─────────────────────────────────────┤
│                                     │
│  ╔═══════════════════════════════╗ │
│  ║  📖 Book Title                ║ │  ← White cards
│  ║  Author Name                  ║ │  
│  ╚═══════════════════════════════╝ │
│                                     │  ← White background
│  ╔═══════════════════════════════╗ │
│  ║  📖 Another Book              ║ │
│  ║  Author Name                  ║ │
│  ╚═══════════════════════════════╝ │
│                                     │
└─────────────────────────────────────┘
```

### Dark Mode
```
┌─────────────────────────────────────┐
│ ☰  Library                       ⚙ │  ← Light app bar
├─────────────────────────────────────┤
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░ ╔═══════════════════════════════╗░│
│░ ║  📖 Book Title                ║░│  ← Dark cards
│░ ║  Author Name                  ║░│  
│░ ╚═══════════════════════════════╝░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  ← Dark background
│░ ╔═══════════════════════════════╗░│
│░ ║  📖 Another Book              ║░│
│░ ║  Author Name                  ║░│
│░ ╚═══════════════════════════════╝░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
└─────────────────────────────────────┘
```

---

## What Gets Themed?

### ✅ Everything in the App!

**Screens**:
- Library screen
- Settings screen  
- Book import dialogs
- All popup menus

**Elements**:
- App bars
- Navigation bars
- Buttons
- Text fields
- Cards and lists
- Icons
- Dividers
- Backgrounds

---

## Reader Themes (Separate)

### Important Note

**App Theme** vs **Reader Theme** are different!

#### App Theme (This Feature)
- Controls: Library, Settings, Navigation
- Options: Light, Dark, Auto
- Location: Settings → Appearance

#### Reader Theme (Existing)
- Controls: Reading screens only
- Options: Light, Dark, Sepia
- Location: Inside each reading mode's settings

### Why Separate?

You can mix and match! Examples:

- **Dark app** + **Light reader** (for better reading)
- **Light app** + **Sepia reader** (for comfort)
- **Auto app** + **Dark reader** (for night reading)

**Configure them independently for maximum flexibility!**

---

## Tips & Tricks

### 💡 Tip 1: Auto Mode is Smart
Set to Auto mode and forget about it. Your app will automatically match your system:
- Light during the day
- Dark at night
- Perfect for automatic schedules

### 💡 Tip 2: Save Battery
On phones with OLED screens (most modern smartphones):
- Dark mode saves battery
- Pure black backgrounds use almost no power
- Can extend battery life significantly

### 💡 Tip 3: Reduce Eye Strain
Use dark mode in low-light environments:
- Less blue light exposure
- Easier on eyes at night
- Better for bedtime reading

### 💡 Tip 4: Personal Preference
There's no "best" mode:
- Try each one
- See what feels comfortable
- Change anytime you want

---

## Troubleshooting

### Q: Theme doesn't change immediately?
**A**: It should! Make sure you're clicking the buttons in Settings → Appearance. The change is instant.

### Q: Auto mode not following my system?
**A**: On some older systems, you may need to close and reopen the app after changing system theme.

### Q: Want different themes for library and reading?
**A**: Yes! App theme (Settings → Appearance) controls the library. Reader theme (inside each reader) controls reading screens. They're independent.

### Q: Theme resets after restart?
**A**: It shouldn't. Your choice is saved automatically. If this happens, it's a bug - please report it.

### Q: Can I schedule theme changes?
**A**: Not yet, but Auto mode will follow your OS if your OS has scheduling.

---

## Keyboard Shortcuts

When the app has focus:

| Action | Shortcut |
|--------|----------|
| Open Settings | No direct shortcut |
| Toggle Theme | No direct shortcut |

**Quick Access**: Click Settings icon (⚙) in any app bar

---

## Platform-Specific Notes

### 🐧 Linux
- Detects GTK/KDE theme automatically (Auto mode)
- Instant switching supported
- Persists in `~/.local/share/shared_preferences`

### 🪟 Windows
- Detects Windows theme automatically (Auto mode)
- Instant switching supported
- Persists in app data folder

### 🌐 Web
- Detects browser/OS theme preference (Auto mode)
- Instant switching supported
- Persists in browser local storage

### 📱 Android
- Detects Android dark mode setting (Auto mode)
- Instant switching supported
- Follows system dark mode schedule

### 🍎 iOS
- Detects iOS dark mode setting (Auto mode)
- Instant switching supported
- Follows system appearance schedule

---

## Summary

### Quick Reference

**To enable dark mode**:
1. Settings → Appearance → Dark 🌙

**To enable light mode**:
1. Settings → Appearance → Light 🌞

**To follow system**:
1. Settings → Appearance → Auto 🔄

**Changes apply**: Instantly ⚡

**Saved automatically**: Yes ✅

**Works everywhere**: All platforms ✅

---

## Need More Help?

- **Full Documentation**: See `DARK_MODE_FEATURE.md`
- **Technical Details**: See `DARK_MODE_SUMMARY.md`
- **All Features**: See `SESSION_SUMMARY.md`

---

**Enjoy your new dark mode!** 🌙✨

*Tip: Try Auto mode first - it's the most convenient!*
