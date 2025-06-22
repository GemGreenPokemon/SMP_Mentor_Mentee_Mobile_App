# Excessive API Calls Investigation - Announcements Screen

## Issue Summary
The Firebase Functions emulator logs show excessive calls to `getAnnouncementsList`, with multiple calls happening within the same second, causing performance issues and emulator overload.

## Log Evidence
```
21:25:39 I function[us-central1-getAnnouncementsList] Beginning execution of "us-central1-getAnnouncementsList"
21:25:39 I function[us-central1-getAnnouncementsList] Finished "us-central1-getAnnouncementsList" in 48.8578ms
21:25:39 I function[us-central1-getAnnouncementsList] Beginning execution of "us-central1-getAnnouncementsList"
21:25:39 I function[us-central1-getAnnouncementsList] Finished "us-central1-getAnnouncementsList" in 50.4983ms
[... pattern repeats multiple times within the same second ...]
```

## Root Cause Analysis

### Primary Issue: FutureBuilder in AnnouncementCard

**Location**: `/lib/screens/web/shared/web_announcements/widgets/announcement_card.dart` (lines 146-169)

```dart
FutureBuilder<bool>(
  future: announcementService.canEditAnnouncement(announcement['created_by'] ?? ''),
  builder: (context, snapshot) {
    if (snapshot.data == true) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            color: Colors.grey[600],
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red[400],
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  },
),
```

### Call Chain That Causes Excessive API Calls

1. **WebAnnouncementsScreen** (`/lib/screens/web/shared/web_announcements/web_announcements_screen.dart`)
   - Uses `Consumer<AnnouncementService>` (line 243-244)
   - Rebuilds whenever AnnouncementService notifies listeners

2. **AnnouncementGrid** (`/lib/screens/web/shared/web_announcements/widgets/announcement_grid.dart`)
   - Renders multiple AnnouncementCard widgets
   - Each card creates its own FutureBuilder

3. **AnnouncementCard** (`/lib/screens/web/shared/web_announcements/widgets/announcement_card.dart`)
   - Contains FutureBuilder that calls `canEditAnnouncement()` for EACH card
   - This FutureBuilder re-executes on every rebuild

4. **AnnouncementService.canEditAnnouncement()** (`/lib/services/announcement_service.dart`, lines 209-229)
   ```dart
   Future<bool> canEditAnnouncement(String createdBy) async {
     try {
       final userRole = await _authService.getUserRole();  // This triggers API calls
       final currentUser = _authService.currentUser;
       
       // Coordinators can edit any announcement
       if (userRole == 'coordinator') {
         return true;
       }
       
       // Mentors can only edit their own announcements
       if (userRole == 'mentor' && currentUser?.uid == createdBy) {
         return true;
       }
       
       return false;
     } catch (e) {
       debugPrint('Error checking edit permissions: $e');
       return false;
     }
   }
   ```

## Why This Causes Excessive Calls

1. **No Caching**: The `canEditAnnouncement` method doesn't cache its result
2. **FutureBuilder Behavior**: FutureBuilder re-executes its future on every rebuild
3. **Multiple Cards**: With N announcement cards, each rebuild causes N API calls
4. **Parent Widget Rebuilds**: The Consumer pattern causes frequent rebuilds
5. **Cascade Effect**: Each notification from AnnouncementService triggers all cards to rebuild

## Impact

- **Performance**: Each call takes 30-60ms, multiplied by number of cards
- **Emulator Overload**: Firestore emulator becomes unresponsive
- **User Experience**: Causes the pointer/input errors seen in console:
  ```
  Uncaught DartError: Assertion failed: "The targeted input element must be the active input element"
  ```

## Related Files

1. **Main Screen**: `/lib/screens/web/shared/web_announcements/web_announcements_screen.dart`
2. **Grid Widget**: `/lib/screens/web/shared/web_announcements/widgets/announcement_grid.dart`
3. **Card Widget**: `/lib/screens/web/shared/web_announcements/widgets/announcement_card.dart`
4. **Service**: `/lib/services/announcement_service.dart`
5. **Cloud Functions**: `/lib/services/cloud_function_service.dart`

## Recommended Solution: Pre-calculate Edit Permissions

This is the industry-standard approach for handling permissions in list views. It follows the principle of "calculate once, use many times" and is widely recommended for performance optimization in Flutter applications.

### Why This Is The Best Solution

1. **Performance**: Reduces API calls from O(n) to O(1) - one call instead of one per card
2. **Simplicity**: Removes async complexity from the UI layer
3. **Reliability**: No race conditions or loading states in individual cards
4. **Maintainability**: Permissions logic stays in the service layer, not scattered in UI
5. **Industry Standard**: This pattern is recommended by Flutter documentation and performance guides

### Implementation Details

#### Step 1: Modify AnnouncementService.fetchAnnouncements()

Update the `fetchAnnouncements` method in `/lib/services/announcement_service.dart` (around line 47):

```dart
// In AnnouncementService.fetchAnnouncements()
if (result['success'] == true && result['data'] != null) {
  // Get user info ONCE at the beginning
  final currentUserId = _authService.currentUser?.uid;
  final userRole = await _authService.getUserRole();
  
  final List<dynamic> rawAnnouncements = result['data'];
  _announcements = rawAnnouncements.map((announcement) {
    final Map<String, dynamic> announcementMap = Map<String, dynamic>.from(announcement);
    
    // Pre-calculate edit permission for this announcement
    bool canEdit = false;
    if (userRole == 'coordinator') {
      canEdit = true;  // Coordinators can edit all announcements
    } else if (userRole == 'mentor' && announcementMap['created_by'] == currentUserId) {
      canEdit = true;  // Mentors can edit their own announcements
    }
    
    return {
      'id': announcementMap['id'],
      'title': announcementMap['title'],
      'content': announcementMap['content'],
      'time': _formatAnnouncementTime(announcementMap['created_at']),
      'priority': announcementMap['priority'] ?? 'none',
      'target_audience': announcementMap['target_audience'],
      'created_by': announcementMap['created_by'],
      'canEdit': canEdit,  // Add pre-calculated permission
    };
  }).toList();
  _lastFetchTime = DateTime.now();
}
```

#### Step 2: Update AnnouncementCard Widget

Replace the FutureBuilder in `/lib/screens/web/shared/web_announcements/widgets/announcement_card.dart` (lines 146-169):

```dart
// REMOVE the FutureBuilder and replace with:
if (announcement['canEdit'] == true) {
  return Row(
    children: [
      IconButton(
        icon: const Icon(Icons.edit, size: 18),
        color: Colors.grey[600],
        onPressed: onEdit,
        tooltip: 'Edit',
      ),
      IconButton(
        icon: const Icon(Icons.delete, size: 18),
        color: Colors.red[400],
        onPressed: onDelete,
        tooltip: 'Delete',
      ),
    ],
  );
} else {
  return const SizedBox.shrink();
}
```

#### Step 3: Remove or Deprecate canEditAnnouncement Method

The `canEditAnnouncement` method in AnnouncementService (lines 209-229) becomes unnecessary. You can either:
- Remove it entirely
- Mark it as deprecated: `@deprecated('Use pre-calculated canEdit field instead')`

### How It Works

1. **On Initial Load**: 
   - Fetch announcements → Get user role once → Calculate all permissions → Store in data

2. **On Update/Create/Delete**:
   - The existing code already calls `fetchAnnouncements(forceRefresh: true)`
   - This automatically recalculates all permissions with fresh data

3. **On Pull-to-Refresh**:
   - Should call `fetchAnnouncements(forceRefresh: true)`
   - Permissions are recalculated with fresh data

### Performance Impact

For a typical scenario with 20 announcements:
- **Before**: 20+ API calls on initial load, 20+ on each rebuild
- **After**: 1 API call total
- **Improvement**: ~95% reduction in API calls

### Additional Benefits

1. **Consistent State**: Permissions are always in sync with the announcement data
2. **Offline Capable**: Once loaded, no additional network calls needed
3. **Predictable Behavior**: No timing issues or race conditions
4. **Better Testing**: Easier to unit test without async complexity

## Additional Observations

1. **Animation Overhead**: Each card has TweenAnimationBuilder which adds to rebuild cost
2. **No Debouncing**: Search and filter operations trigger immediate rebuilds
3. **Missing Keys**: GridView.builder doesn't use keys, causing unnecessary widget recreation

## Testing the Fix

After implementing a solution, verify by:
1. Monitoring Firebase emulator logs for reduced function calls
2. Checking browser console for elimination of pointer errors
3. Testing emulator UI responsiveness at localhost:4000
4. Measuring page performance with Chrome DevTools

## Prevention

1. Avoid FutureBuilder for operations that depend on static data
2. Pre-calculate derived data when fetching from API
3. Use proper state management (Provider/Riverpod/Bloc) for shared state
4. Implement caching for expensive operations
5. Add debouncing for user input that triggers API calls