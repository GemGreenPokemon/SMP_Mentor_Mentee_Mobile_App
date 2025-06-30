import 'package:flutter/material.dart';

class DateTimeHelpers {
  static String formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  static DateTime parseTime(String timeStr, DateTime? selectedDay) {
    // Parse time string like "2:00 PM" to DateTime
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1] == 'PM';
    
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    
    final now = selectedDay ?? DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static String formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String formatDateForDatabase(DateTime date) {
    // Format: YYYY-MM-DD
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  static String createISODateTime(DateTime date, DateTime time) {
    // Combine date and time into a single DateTime in local timezone
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    
    // Get timezone offset
    final offset = combined.timeZoneOffset;
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes.abs() % 60);
    final sign = offset.isNegative ? '-' : '+';
    
    // Format with explicit timezone offset
    final year = combined.year.toString().padLeft(4, '0');
    final month = combined.month.toString().padLeft(2, '0');
    final day = combined.day.toString().padLeft(2, '0');
    final hour = combined.hour.toString().padLeft(2, '0');
    final minute = combined.minute.toString().padLeft(2, '0');
    final offsetStr = '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    
    // Return ISO string with timezone offset (e.g., 2025-07-03T17:00:00-07:00)
    return '$year-$month-${day}T$hour:$minute:00$offsetStr';
  }

  static List<DateTime> generateTimeSlots() {
    List<DateTime> slots = [];
    final now = DateTime.now();
    
    // Generate time slots from 8 AM to 8 PM in 30-minute intervals
    for (int hour = 8; hour <= 20; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 20 && minute > 0) break; // Stop at 8:00 PM
        slots.add(DateTime(now.year, now.month, now.day, hour, minute));
      }
    }
    
    return slots;
  }

  static Color getSlotColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.lightBlue;
      case 'Pending':
        return Colors.blue[600]!;
      case 'Booked':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  static Color getSlotTextColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.lightBlue[700]!;
      case 'Pending':
        return Colors.blue[600]!;
      case 'Booked':
        return Colors.indigo[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
