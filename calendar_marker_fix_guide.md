# Calendar Marker Alignment Fix Guide

## Problem Identified
The calendar dots (markers) are not properly aligned because the `Positioned` widget was being used inside the `markerBuilder`, which is incorrect. The table_calendar package handles positioning internally.

## Changes Made

### 1. Removed Positioned Widget
**Before:**
```dart
markerBuilder: (context, day, events) {
  if (events.isNotEmpty) {
    return Positioned(  // ❌ Incorrect
      bottom: 1,
      child: Row(...),
    );
  }
}
```

**After:**
```dart
markerBuilder: (context, day, events) {
  if (events.isNotEmpty) {
    return Row(  // ✅ Correct
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: events.take(3).map((event) {
        // ... marker containers
      }).toList(),
    );
  }
}
```

### 2. Added CalendarStyle Properties
Added proper marker alignment properties to `CalendarStyle`:
```dart
calendarStyle: CalendarStyle(
  // ... other properties
  markersAlignment: Alignment.bottomCenter,
  markersMaxCount: 3,
  markersOffset: const PositionedOffset(bottom: 1),
),
```

## How table_calendar Handles Markers

1. **Automatic Positioning**: The calendar widget automatically positions markers based on the `markersAlignment` property
2. **Marker Container**: Each day cell has a designated area for markers
3. **Row Layout**: Multiple markers are displayed in a row format
4. **Offset Control**: Use `markersOffset` to fine-tune position

## Alternative Approaches

### 1. Single Marker Builder
If you need more control over individual markers:
```dart
calendarBuilders: CalendarBuilders(
  singleMarkerBuilder: (context, day, event) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _getEventColor(event),
        shape: BoxShape.circle,
      ),
    );
  },
),
```

### 2. Custom Day Cell Builder
For complete control over the day cell layout:
```dart
calendarBuilders: CalendarBuilders(
  defaultBuilder: (context, day, focusedDay) {
    // Build entire day cell with custom marker positioning
  },
),
```

### 3. Marker Styling Options
Additional CalendarStyle properties:
- `markerDecoration`: Default decoration for all markers
- `markersMaxCount`: Limit number of visible markers
- `markerSize`: Control marker dimensions
- `markerMargin`: Space between markers

## Testing the Fix

1. Run the app and navigate to the schedule meeting screen
2. Check that markers appear at the bottom center of day cells
3. Verify multiple markers are displayed horizontally
4. Confirm markers don't overlap or misalign

## Files Modified
- `/lib/screens/web_schedule_meeting_screen.dart`
- `/lib/screens/schedule_meeting_screen.dart`

## Additional Recommendations

1. **Consistent Sizing**: Keep marker sizes small (6-8px) for better visibility
2. **Color Coding**: Use distinct colors for different event types
3. **Limit Display**: Show max 3-4 markers to avoid cluttering
4. **Tooltip/Popup**: Consider showing details on tap/hover for days with many events