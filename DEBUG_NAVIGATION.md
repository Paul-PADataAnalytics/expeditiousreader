# Debug Logging for Page Navigation

**Status**: ⚠️ **Historical Reference Only** (December 9, 2025)

**Note**: All debug logging described in this document has been **removed from production code**. This document is preserved for:
- Future debugging if issues arise
- Understanding the development process
- Reference for implementing similar features

For the current production implementation, see:
- `LAZY_LOADING_IMPLEMENTATION.md` - Architecture documentation
- `BACKWARD_NAV_FIX.md` - Binary search algorithm details
- `PRODUCTION_CLEANUP.md` - Final cleanup summary

---

## Overview (Historical)
This document describes the debug logging that was temporarily added to diagnose the backward navigation issue where turning back a page didn't go back far enough.

**Resolution**: The issue was fixed by improving the binary search algorithm. Debug logs were removed after verification.

## Debug Messages Added

### 1. Page Calculation (`_calculatePage`)
**Location:** `lib/screens/traditional_reader_screen.dart`

**Messages:**
- 📦 `[CACHE]` - When using a cached page
- 🔨 `[CALC]` - When calculating a new page
- ⚠️ `[CALC] WARNING` - When an empty page is returned

**Example Output:**
```
📦 [CACHE] Using cached page for startWordIndex=1234
```
or
```
🔨 [CALC] Calculating new page from startWordIndex=1234
🔨 [CALC] Page calculated: start=1234, end=1456, wordCount=222
📦 [CACHE] Cached page. Cache size: 3
```

### 2. Forward Navigation (`_nextPage`)
**Location:** `lib/screens/traditional_reader_screen.dart`

**Messages:**
- ➡️ `[NEXT_PAGE]` - Navigation details
- Shows current page info
- Shows next page start position
- Shows resulting page info

**Example Output:**
```
➡️ [NEXT_PAGE] Starting forward navigation
   Current page: start=1234, end=1456, wordCount=222
   Total words in book: 50000
   Next page will start at: 1456
   New page: start=1456, end=1678, wordCount=222
   ✅ Navigation complete
```

### 3. Backward Navigation (`_previousPage`)
**Location:** `lib/screens/traditional_reader_screen.dart`

**Messages:**
- ⬅️ `[PREV_PAGE]` - Navigation details
- Shows current page info
- Shows resulting previous page info
- **Calculates gap between pages** (should be 0 for perfect alignment)
- ⚠️ Warning if pages don't align

**Example Output (Perfect Alignment):**
```
⬅️ [PREV_PAGE] Starting backward navigation
   Current page: start=1456, end=1678, wordCount=222
   Total words in book: 50000
   New page: start=1234, end=1456, wordCount=222
   Gap between pages: 0 words
   ✅ Pages align perfectly
   ✅ Navigation complete
```

**Example Output (Misalignment - THE PROBLEM):**
```
⬅️ [PREV_PAGE] Starting backward navigation
   Current page: start=1456, end=1678, wordCount=222
   Total words in book: 50000
   New page: start=1200, end=1400, wordCount=200
   Gap between pages: 56 words
   ⚠️ WARNING: Pages don't align perfectly!
      Previous page ends at: 1400
      Current page starts at: 1456
      Missing/overlapping: 56 words
   ✅ Navigation complete
```

### 4. Binary Search (`_findPreviousPageStart`)
**Location:** `lib/screens/traditional_reader_screen.dart`

**Messages:**
- 🔍 `[PREV_PAGE]` - Binary search progress
- Shows initial guess calculation
- Shows each iteration of the search
- Shows verification step

**Example Output:**
```
🔍 [PREV_PAGE] Finding previous page start. Current page starts at: 1456
   Current page has 222 words. Initial guess: 1123 (went back 333.0 words)
🔍 [PREV_PAGE] Iteration 1: Testing mid=1123 (range: 1123-1455)
   └─ Test page: start=1123, end=1345, wordCount=222
   └─ Page ends at/before target (1456). Moving search window forward.
🔍 [PREV_PAGE] Iteration 2: Testing mid=1400 (range: 1346-1455)
   └─ Test page: start=1400, end=1622, wordCount=222
   └─ ✅ FOUND! Page overlaps with current (starts before, ends after target)
🔍 [PREV_PAGE] Final result: Previous page starts at 1400
```

### 5. Layout Engine (`_layoutSinglePage`)
**Location:** `lib/utils/column_text_layout.dart`

**Messages:**
- 📖 `[LAYOUT]` - Page layout details
- Shows available dimensions
- Shows calculated column width and line metrics
- Shows progress for each column
- Shows final page boundaries

**Example Output:**
```
📖 [LAYOUT] Starting layout for page from word 1234
   └─ Available: 800.0w x 600.0h, Columns: 2, Gap: 32.0
   └─ Column width: 364.0, Line height: 24.0, Max lines/column: 25
   └─ Column 1: 25 lines, ending at word 1345
   └─ Column 2: 25 lines, ending at word 1456
📖 [LAYOUT] Page complete: start=1234, end=1456, wordCount=222
```

## How to Use These Logs

### Running the App with Debug Output

1. **Terminal Method:**
   ```bash
   cd /home/paul/Documents/projects/expeditiousreader
   flutter run -d linux 2>&1 | grep -E "(NEXT_PAGE|PREV_PAGE|CALC|CACHE|LAYOUT)"
   ```

2. **Full Output:**
   ```bash
   flutter run -d linux
   ```
   Then watch the console as you navigate through pages.

### Reproducing the Issue

1. Open a book in traditional reader mode
2. Navigate forward a few pages
3. Navigate backward and watch the logs
4. Look for the **gap between pages** in the `[PREV_PAGE]` output

### What to Look For

#### ✅ **Correct Behavior:**
```
Gap between pages: 0 words
✅ Pages align perfectly
```

#### ❌ **Bug Indicator:**
```
Gap between pages: 56 words
⚠️ WARNING: Pages don't align perfectly!
   Previous page ends at: 1400
   Current page starts at: 1456
   Missing/overlapping: 56 words
```

This means the binary search found a page that **doesn't end exactly where the current page starts**, indicating:
- The algorithm logic may be flawed
- The page calculation might be inconsistent
- There might be a caching issue

### Key Metrics to Track

1. **Word Count Consistency:**
   - Do pages have similar word counts?
   - If word count varies wildly, layout might be inconsistent

2. **Binary Search Iterations:**
   - How many iterations does it take?
   - Does it find the correct page or settle on a wrong one?

3. **Cache Behavior:**
   - Are pages being recalculated unnecessarily?
   - Is the cache interfering with correct results?

4. **Layout Consistency:**
   - Given the same starting word index, does layout produce the same end word index?
   - This should always be true unless settings changed

## Common Issues to Diagnose

### Issue 1: Inconsistent Page Layout
**Symptom:** Same `startWordIndex` produces different `endWordIndex`
**Look for:** Different `[LAYOUT]` outputs for same starting position
**Possible causes:**
- Settings changed between calculations
- Cache wasn't cleared after settings change
- Floating-point rounding differences

### Issue 2: Binary Search Convergence
**Symptom:** Binary search doesn't find the right page
**Look for:** 
- Search settling on wrong page
- "Verification failed" message
**Possible causes:**
- Algorithm logic error
- Off-by-one errors
- Edge case not handled

### Issue 3: Page Gaps
**Symptom:** `Gap between pages: N words` where N > 0
**Look for:** The gap value and which words are missing
**Possible causes:**
- Binary search finds wrong starting position
- Layout produces different results for same input
- Cache contains stale data

### Issue 4: Backward Navigation Too Far
**Symptom:** Going back skips content
**Look for:** Large negative gap (e.g., "Gap between pages: -50 words")
**Possible causes:**
- Binary search overshoots
- Initial guess is too far back

## Next Steps After Debugging

Once you identify the issue from the logs:

1. **If pages don't align:** The binary search algorithm needs refinement
2. **If layout is inconsistent:** The `ColumnTextLayout` engine needs investigation
3. **If cache is the issue:** Cache invalidation logic needs fixing
4. **If initial guess is wrong:** The 1.5x multiplier may need adjustment

## Disabling Debug Logs

To remove debug logs after fixing the issue, search for and delete all lines containing:
- `print('🔍`
- `print('➡️`
- `print('⬅️`
- `print('📦`
- `print('🔨`
- `print('📖`
- `print('   └─`
- `print('⚠️`

Or wrap them in a debug flag:
```dart
const bool _debugNavigation = false;

if (_debugNavigation) {
  print('...');
}
```
