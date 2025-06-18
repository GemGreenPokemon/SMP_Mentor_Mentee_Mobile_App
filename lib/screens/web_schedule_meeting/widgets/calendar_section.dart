import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_event.dart';
import '../utils/date_time_helpers.dart';

class CalendarSection extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, List<CalendarEvent>> calendarEvents;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final VoidCallback onRefresh;

  const CalendarSection({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.calendarEvents,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh calendar',
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TableCalendar<CalendarEvent>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: focusedDay,
              calendarFormat: calendarFormat,
              eventLoader: (day) {                // Normalize the day to midnight for consistent comparison
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final events = calendarEvents[normalizedDay] ?? [];
                
                // Only log if there are events or if it's the selected day
                if (events.isNotEmpty || (day.day == selectedDay?.day && day.month == selectedDay?.month && day.year == selectedDay?.year)) {
                  print('📅 EventLoader: ${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')} -> ${events.length} events');
                  if (events.isNotEmpty) {
                    for (var event in events) {
                      print('   • ${event.time} - ${event.status} (${event.type})');
                    }
                  }
                }
                
                return events;
              },
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              onDaySelected: onDaySelected,
              onFormatChanged: onFormatChanged,
              onPageChanged: onPageChanged,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF0F2D52),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0x800F2D52),
                  shape: BoxShape.circle,
                ),                markersAlignment: Alignment.bottomCenter,
                markersMaxCount: 3,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Color(0xFF0F2D52),
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Colors.white,
                ),
              ),
              calendarBuilders: CalendarBuilders<CalendarEvent>(
                markerBuilder: (context, day, events) {
                  print('DEBUG: markerBuilder called for $day with ${events.length} events');
                  if (events.isEmpty) return null;

                  // Create ALL dots as indigo/blue baseline since they align correctly
                  // Sort to ensure consistent order: Available, Pending, Booked
                  final statusOrder = {'Available': 0, 'Pending': 1, 'Pending Request': 1, 'Booked': 2};
                  final sortedEvents = List<CalendarEvent>.from(events)
                    ..sort((a, b) => (statusOrder[a.status] ?? 99).compareTo(statusOrder[b.status] ?? 99));

                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 2),                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: sortedEvents.take(3).map((event) {
                        // Use red as baseline template, only change color
                        Color dotColor = Colors.indigo; // Start with indigo template
                        
                        if (event.status == 'Available') {
                          dotColor = Colors.lightBlue;
                        } else if (event.status == 'Pending' || event.status == 'Pending Request') {
                          dotColor = Colors.blue[600]!;
                        } else if (event.status == 'Booked') {
                          dotColor = Colors.indigo;
                        }
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),            
            // Show events for selected day
            if (selectedDay != null && calendarEvents[selectedDay] != null && calendarEvents[selectedDay]!.isNotEmpty) ...[
              _buildEventsForSelectedDay(selectedDay!, calendarEvents[selectedDay]!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventsForSelectedDay(DateTime day, List<CalendarEvent> events) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Events on ${DateTimeHelpers.formatDate(day)}',
                style: const TextStyle(                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...events.map((event) {
            Color dotColor = Colors.grey;
            IconData icon = Icons.circle;
            
            if (event.status == 'Available') {
              dotColor = Colors.lightBlue;
              icon = Icons.access_time;
            } else if (event.status == 'Pending') {
              dotColor = Colors.blue[600]!;
              icon = Icons.hourglass_empty;
            } else if (event.status == 'Booked') {
              dotColor = Colors.indigo;
              icon = Icons.check_circle;
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: dotColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(                      children: [
                        Text(
                          event.time,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: dotColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: dotColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (event.type == 'meeting') ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Meeting scheduled',
                              style: TextStyle(                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}