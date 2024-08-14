// import 'dart:io';
// import 'package:args/args.dart';

// // Event class
// class Event {
//   String title;
//   DateTime date;
//   String time;
//   String location;
//   String description;

//   Event({
//     required this.title,
//     required this.date,
//     required this.time,
//     required this.location,
//     required this.description,
//   });

//   @override
//   String toString() {
//     return '$title - ${date.toLocal()} at $time in $location';
//   }
// }

// // Attendance class
// class Attendance {
//   String eventTitle;
//   List<String> attendees;
//   Map<String, bool> presence;

//   Attendance({
//     required this.eventTitle,
//     required this.attendees,
//     required this.presence,
//   });
// }

// // Scheduler class
// class Scheduler {
//   List<Event> events;

//   Scheduler(this.events);

//   List<Event> getUpcomingEvents() {
//     DateTime now = DateTime.now();
//     return events.where((event) => event.date.isAfter(now)).toList();
//   }

//   List<Event> getPastEvents() {
//     DateTime now = DateTime.now();
//     return events.where((event) => event.date.isBefore(now)).toList();
//   }

//   bool hasConflict(Event newEvent) {
//     return events.any((event) =>
//       event.date == newEvent.date && event.time == newEvent.time);
//   }

//   List<Event> getEventsInChronologicalOrder() {
//     return List.from(events)..sort((a, b) => a.date.compareTo(b.date));
//   }
// }

// // Storage class
// class Storage {
//   final String filePath;

//   Storage(this.filePath);

//   Future<void> saveEvents(List<Event> events) async {
//     File file = File(filePath);
//     String content = events.map((event) =>
//         '${event.title},${event.date},${event.time},${event.location},${event.description}'
//     ).join('\n');
//     await file.writeAsString(content);
//   }

//   Future<List<Event>> loadEvents() async {
//     File file = File(filePath);
//     if (await file.exists()) {
//       String content = await file.readAsString();
//       List<Event> events = content.split('\n').map((line) {
//         List<String> parts = line.split(',');
//         return Event(
//           title: parts[0],
//           date: DateTime.parse(parts[1]),
//           time: parts[2],
//           location: parts[3],
//           description: parts[4],
//         );
//       }).toList();
//       return events;
//     }
//     return [];
//   }

//   Future<void> saveAttendance(String eventTitle, Attendance attendance) async {
//     File file = File('$eventTitle-attendance.txt');
//     String content = 'Attendees:\n${attendance.attendees.join('\n')}\n\nPresence:\n${attendance.presence.entries.map((e) => '${e.key}: ${e.value}').join('\n')}';
//     await file.writeAsString(content);
//   }

//   Future<Attendance> loadAttendance(String eventTitle) async {
//     File file = File('$eventTitle-attendance.txt');
//     if (await file.exists()) {
//       String content = await file.readAsString();
//       List<String> sections = content.split('\n\n');
//       List<String> attendees = sections[0].split('\n').skip(1).toList();
//       Map<String, bool> presence = {};
//       sections[1].split('\n').skip(1).forEach((line) {
//         List<String> parts = line.split(': ');
//         if (parts.length == 2) {
//           presence[parts[0]] = parts[1] == 'true';
//         }
//       });
//       return Attendance(
//         eventTitle: eventTitle,
//         attendees: attendees,
//         presence: presence,
//       );
//     }
//     return Attendance(eventTitle: eventTitle, attendees: [], presence: {});
//   }
// }

// void main(List<String> arguments) async {
//   final parser = ArgParser()
//     ..addCommand('add_event')
//     ..addCommand('list_events')
//     ..addCommand('edit_event')
//     ..addCommand('delete_event')
//     ..addCommand('register_attendance')
//     ..addCommand('view_attendance')
//     ..addCommand('mark_attendance');

//   final ArgResults argResults = parser.parse(arguments);
//   String filePath = 'events.txt';
//   Storage storage = Storage(filePath);

//   List<Event> events = await storage.loadEvents();
//   Scheduler scheduler = Scheduler(events);

//   if (argResults.command?.name == 'add_event') {
//     print('Enter event title:');
//     String title = stdin.readLineSync()!;
//     print('Enter event date (2024-09-08):');
//     DateTime date = DateTime.parse(stdin.readLineSync()!);
//     print('Enter event time (12:00):');
//     String time = stdin.readLineSync()!;
//     print('Enter event location(rad5 tech hub event management)');
//     String location = stdin.readLineSync()!;
//     print('Enter event description(all work is done)');
//     String description = stdin.readLineSync()!;

//     Event newEvent = Event(title: title, date: date, time: time, location: location, description: description);

//     if (scheduler.hasConflict(newEvent)) {
//       print('Conflict detected! Event overlaps with an existing event.');
//     } else {
//       events.add(newEvent);
//       await storage.saveEvents(events);
//       print('Event added successfully.');
//     }
//   } else if (argResults.command?.name == 'edit_event') {
//     print('Enter the title of the event to edit:');
//     String oldTitle = stdin.readLineSync()!;
//     Event? eventToEdit = events.firstWhere((event) => event.title == oldTitle, orElse: () => Event(title: '', date: DateTime(0000), time: '', location: '', description: ''));

//     if (eventToEdit != null) {
//       print('Enter new title (leave blank to keep the same):');
//       String title = stdin.readLineSync()!;
//       if (title.isNotEmpty) eventToEdit.title = title;

//       print('Enter new date (YYYY-MM-DD, leave blank to keep the same):');
//       String dateStr = stdin.readLineSync()!;
//       if (dateStr.isNotEmpty) eventToEdit.date = DateTime.parse(dateStr);

//       print('Enter new time (HH:MM, leave blank to keep the same):');
//       String time = stdin.readLineSync()!;
//       if (time.isNotEmpty) eventToEdit.time = time;

//       print('Enter new location (leave blank to keep the same):');
//       String location = stdin.readLineSync()!;
//       if (location.isNotEmpty) eventToEdit.location = location;

//       print('Enter new description (leave blank to keep the same):');
//       String description = stdin.readLineSync()!;
//       if (description.isNotEmpty) eventToEdit.description = description;

//       await storage.saveEvents(events);
//       print('Event updated successfully.');
//     } else {
//       print('Event not found.');
//     }
//   } else if (argResults.command?.name == 'delete_event') {
//     print('Enter the title of the event to delete:');
//     String title = stdin.readLineSync()!;
//     events.removeWhere((event) => event.title == title);

//     await storage.saveEvents(events);
//     print('Event deleted successfully.');
//   } else if (argResults.command?.name == 'list_events') {
//     List<Event> upcomingEvents = scheduler.getUpcomingEvents();
//     List<Event> pastEvents = scheduler.getPastEvents();

//     print('Upcoming Events:');
//     for (var event in scheduler.getEventsInChronologicalOrder()) {
//       if (event.date.isAfter(DateTime.now())) {
//         print(event);
//       }
//     }

//     print('\nPast Events:');
//     for (var event in scheduler.getEventsInChronologicalOrder()) {
//       if (event.date.isBefore(DateTime.now())) {
//         print(event);
//       }
//     }
//   } else if (argResults.command?.name == 'register_attendance') {
//     print('Enter event title to register attendance:');
//     String eventTitle = stdin.readLineSync()!;
//     print('Enter attendee name:');
//     String attendeeName = stdin.readLineSync()!;

//     Attendance attendance = await storage.loadAttendance(eventTitle);
//     if (!attendance.attendees.contains(attendeeName)) {
//       attendance.attendees.add(attendeeName);
//       attendance.presence[attendeeName] = false;
//       await storage.saveAttendance(eventTitle, attendance);
//       print('Attendee $attendeeName registered for event $eventTitle.');
//     } else {
//       print('Attendee already registered.');
//     }
//   } else if (argResults.command?.name == 'view_attendance') {
//     print('Enter event title to view attendance:');
//     String eventTitle = stdin.readLineSync()!;

//     Attendance attendance = await storage.loadAttendance(eventTitle);
//     print('Attendees for $eventTitle:');
//     for (var attendee in attendance.attendees) {
//       String status = attendance.presence[attendee] == true ? 'Present' : 'Absent';
//       print('$attendee: $status');
//     }
//   } else if (argResults.command?.name == 'mark_attendance') {
//     print('Enter event title:');
//     String eventTitle = stdin.readLineSync()!;
//     print('Enter attendee name:');
//     String attendeeName = stdin.readLineSync()!;
//     print('Mark as (present/absent):');
//     String status = stdin.readLineSync()!;
//     bool isPresent = status.toLowerCase() == 'present';

//     Attendance attendance = await storage.loadAttendance(eventTitle);
//     if (attendance.attendees.contains(attendeeName)) {
//       attendance.presence[attendeeName] = isPresent;
//       await storage.saveAttendance(eventTitle, attendance);
//       print('Attendance status updated for $attendeeName.');
//     } else {
//       print('Attendee not found.');
//     }
//   } else {
//     print('Unknown command. Available commands are: add_event, list_events, edit_event, delete_event, register_attendance, view_attendance, mark_attendance');
//   }
// }
