import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'schedule_meeting_screen_calendar_view.dart';

class CalendarViewTest extends StatelessWidget {
  const CalendarViewTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider(
      controller: EventController(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduleMeetingScreenCalendarView(isMentor: true),
                      ),
                    );
                  },
                  child: const Text('Test Calendar View (Mentor)'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduleMeetingScreenCalendarView(isMentor: false),
                      ),
                    );
                  },
                  child: const Text('Test Calendar View (Mentee)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}