# QuotaExceededError Fix - Web Storage Issue

## Problem
When importing books in web mode, the app crashed with:
```
QuotaExceededError: Failed to execute 'setItem' on 'Storage': Setting the value of 'flutter.book_cover_2993daa0-d7e8-4944-8ca5-8753fba579c6' exceeded the quota.
```

**Root Cause**: 
- Book cover images stored as base64 strings in browser's localStorage (via SharedPreferences)
- localStorage has a 5-10MB limit per domain
- Base64 encoding increases file size by ~1.33x
- Multiple large cover images quickly exceeded quota

## Solution
Implemented graceful degradation: Skip cover images when they're too large, but still import the book successfully.

### Changes Made

#### 1. Library Service (`lib/services/library_service.dart`)
- Modified `importBookFromBytes()` return type: `Future<Book>` → `Future<Map<String, dynamic>>`
- Added 500KB size limit check for base64 cover data on web
- Added try-catch block to handle QuotaExceededError gracefully
- Returns warnings alongside book data when covers are skipped

**Key Logic**:
```dart
if (coverData.length > 500000) {
  coverPath = null;
  warning = 'Cover image skipped (too large for web storage)';
} else {
  try {
    await prefs.setString(coverPath, coverData);
  } catch (e) {
    if (e.toString().contains('QuotaExceededError') || 
        e.toString().contains('quota')) {
      coverPath = null;
      warning = 'Cover image skipped (storage quota exceeded)';
    } else {
      rethrow;
    }
  }
}
```

#### 2. Library Provider (`lib/providers/library_provider.dart`)
- Updated `importBooksFromBytes()` to handle new return type
- Added warnings collection alongside errors
- Returns warnings in result map for UI display

#### 3. Library Screen (`lib/screens/library_screen.dart`)
- Added warning display in import results dialog
- Shows orange warning messages when covers are skipped
- Added `SingleChildScrollView` for better handling of multiple messages

## Benefits
✅ **No crashes** - Quota errors handled gracefully  
✅ **No data loss** - Book content always preserved, only covers skipped  
✅ **User feedback** - Clear warning messages explain what happened  
✅ **Graceful degradation** - Books work fine without covers  
✅ **Future-proof** - Can add image compression enhancement later  

## Testing
- ✅ No compilation errors
- ✅ Web build completes successfully
- ✅ Code follows existing patterns and style

## Future Enhancements
Consider implementing image compression before storage:
- Resize large images to reasonable dimensions (e.g., 300x400px max)
- Convert to WebP format for better compression
- This would allow more covers to fit in localStorage
