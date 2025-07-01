# Cleared Meetings System Improvement Plan

**Date**: July 1, 2025  
**Author**: Claude  
**Issue**: Cleared/hidden meetings count against query limits, preventing new meetings from appearing

## Problem Statement

The current implementation has a fundamental flaw:
1. Meetings are queried from Firestore with a limit (was 5, then 20)
2. Hidden meetings are filtered out **after** the query
3. This means hidden meetings consume query slots, preventing visible meetings from appearing
4. Example: With 5 hidden meetings and a limit of 5, no new meetings would show up

## Current Implementation

### How Meetings Are Hidden
- When a user clears a meeting, their UID is added to a `hidden_by` array
- The dashboard filters out meetings where the current user's UID is in this array
- This filtering happens client-side after fetching from Firestore

### The Problem
```dart
// Current approach - problematic
.where('mentee_doc_id', isEqualTo: menteeDocId)
.limit(5)  // Hidden meetings count against this limit!
.get()
// Then filter hidden meetings in memory
```

## Proposed Solutions

### Option 1: Boolean Visibility Fields (Recommended)
Replace the `hidden_by` array with explicit boolean fields:

**Database Structure**:
```typescript
{
  // ... other meeting fields
  visible_to_mentor: boolean,
  visible_to_mentee: boolean
}
```

**Benefits**:
- Can query directly: `.where('visible_to_mentee', isEqualTo: true)`
- Hidden meetings don't count against query limits
- Better performance - filtering happens at database level
- Simpler mental model

**Implementation**:
1. Add migration to convert existing `hidden_by` arrays to boolean fields
2. Update cloud functions to set visibility booleans instead of array manipulation
3. Update queries to filter by visibility

### Option 2: Archive Collection (Clean Architecture)
Move cleared meetings to a separate archive collection:

**Structure**:
```
/meetings          // Active meetings only
/meetings_archive  // Cleared/hidden meetings
```

**Benefits**:
- Main meetings collection stays clean
- No query complexity for active meetings
- Preserved history in archive
- Can implement "restore from archive" feature

**Implementation**:
1. When clearing a meeting, move document to archive collection
2. Add metadata about who archived and when
3. Remove from main meetings collection
4. Optional: Build archive viewer for historical data

### Option 3: Composite Visibility Field (Compromise)
Add a single field that tracks overall visibility:

**Database Structure**:
```typescript
{
  // ... other meeting fields
  visibility_status: 'visible' | 'hidden_by_mentor' | 'hidden_by_mentee' | 'hidden_by_both'
}
```

**Benefits**:
- Single field to query
- Can still track who hid the meeting
- Queryable at database level

**Drawbacks**:
- More complex state management
- Harder to query for specific user's visible meetings

### Option 4: Soft Delete with Status (Simple)
Add cleared/hidden as a meeting status:

**Database Structure**:
```typescript
{
  status: 'pending' | 'confirmed' | 'cancelled' | 'rejected' | 'cleared',
  cleared_by: string[] // Track who cleared it
}
```

**Benefits**:
- Fits existing status model
- Easy to implement
- Can exclude from queries: `.where('status', '!=', 'cleared')`

**Drawbacks**:
- Firestore doesn't support '!=' queries well with other conditions
- May need to explicitly list wanted statuses

## Migration Strategy

### Phase 1: Immediate Fix (Completed)
- ✅ Removed query limits to prevent hidden meetings from blocking visible ones
- This is a temporary fix that may impact performance with many meetings

### Phase 2: Implement Chosen Solution
1. Choose between Options 1-4 based on team preferences
2. Create migration script for existing data
3. Update cloud functions
4. Update client queries
5. Test thoroughly with existing data

### Phase 3: Performance Optimization
1. Re-add reasonable query limits (e.g., 50-100)
2. Implement pagination if needed
3. Add date-based filtering (only show future + recent past meetings)
4. Consider caching strategies

## Recommended Approach

**Short term**: Keep current solution (no limits) if performance is acceptable

**Long term**: Implement Option 1 (Boolean Visibility Fields) because:
- Most straightforward to query
- Best performance characteristics  
- Clearest mental model
- Easiest to extend (e.g., add visibility to other user types)

## Additional Considerations

### Date Filtering
Consider adding date filters to reduce query size:
```dart
final DateTime cutoffDate = DateTime.now().subtract(Duration(days: 30));
.where('start_time', '>=', Timestamp.fromDate(cutoffDate))
```

### Pagination
For users with many meetings, implement pagination:
- Load first 20 meetings
- "Load more" button for older meetings
- Infinite scroll on web

### Performance Monitoring
- Track query execution time
- Monitor number of meetings per user
- Alert if any user has > 100 active meetings

## Conclusion

The current hidden meeting system works functionally but has architectural limitations. The proposed solutions would make cleared meetings truly "not count against you" by either:
1. Making them queryable as hidden (Option 1)
2. Moving them elsewhere (Option 2)
3. Marking them in a queryable way (Options 3 & 4)

This would create a more scalable and intuitive system where clearing a meeting truly removes it from your active view without impacting query performance or limits.