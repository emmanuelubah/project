import 'dart:io';

class Event {
  String title;
  DateTime date;
  String time;
  String location;
  String description;

  Event({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
  });

  @override
  String toString() {
    return '$title - ${date.toLocal()} at $time in $location';
  }
}

enum AttendanceStatus { present, absent }

class Attendance {
  String eventTitle;
  List<String> attendees;
  Map<String, AttendanceStatus> presence;

  Attendance({
    required this.eventTitle,
    required this.attendees,
    required this.presence,
  });
}

class Scheduler {
  List<Event> events;

  Scheduler(this.events);

  List<Event> getUpcomingEvents() {
    DateTime now = DateTime.now();
    return events.where((event) => event.date.isAfter(now)).toList();
  }

  List<Event> getPastEvents() {
    DateTime now = DateTime.now();
    return events.where((event) => event.date.isBefore(now)).toList();
  }

  bool hasConflict(Event newEvent) {
    return events.any((event) =>
        event.date == newEvent.date && event.time == newEvent.time);
  }

  List<Event> getEventsInChronologicalOrder() {
    return List.from(events)..sort((a, b) => a.date.compareTo(b.date));
  }
}

class Storage {
  final String filePath;

  Storage(this.filePath);

  Future<void> saveEvents(List<Event> events) async {
    File file = File(filePath);
    String content = events.map((event) =>
        '${event.title},${event.date.toIso8601String()},${event.time},${event.location},${event.description}'
    ).join('\n');
    await file.writeAsString(content);
  }

  Future<List<Event>> loadEvents() async {
    File file = File(filePath);
    if (await file.exists()) {
      String content = await file.readAsString();
      List<Event> events = content.split('\n').map((line) {
        List<String> parts = line.split(',');
        return Event(
          title: parts[0],
          date: DateTime.parse(parts[1]),
          time: parts[2],
          location: parts[3],
          description: parts[4],
        );
      }).toList();
      return events;
    }
    return [];
  }

  Future<void> saveAttendance(String eventTitle, Attendance attendance) async {
    File file = File('${sanitizeFileName(eventTitle)}-attendance.txt');
    String content = 'Attendees:\n${attendance.attendees.join('\n')}\n\nPresence:\n${attendance.presence.entries.map((e) => '${e.key}: ${e.value.name}').join('\n')}';
    await file.writeAsString(content);
  }

  Future<Attendance> loadAttendance(String eventTitle) async {
    File file = File('${sanitizeFileName(eventTitle)}-attendance.txt');
    if (await file.exists()) {
      String content = await file.readAsString();
      List<String> sections = content.split('\n\n');
      List<String> attendees = sections[0].split('\n').skip(1).toList();
      Map<String, AttendanceStatus> presence = {};
      sections[1].split('\n').skip(1).forEach((line) {
        List<String> parts = line.split(': ');
        if (parts.length == 2) {
          presence[parts[0]] = parts[1] == 'present'
              ? AttendanceStatus.present
              : AttendanceStatus.absent;
        }
      });
      return Attendance(
        eventTitle: eventTitle,
        attendees: attendees,
        presence: presence,
      );
    }
    return Attendance(eventTitle: eventTitle, attendees: [], presence: {});
  }

  String sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}

void main() async {
  String filePath = 'events.txt';
  Storage storage = Storage(filePath);

  List<Event> events = await storage.loadEvents();
  Scheduler scheduler = Scheduler(events);

  while (true) {
    print('\nChoose an action:');
    print('1. Add Event');
    print('2. List Events');
    print('3. Edit Event');
    print('4. Delete Event');
    print('5. Register Attendance');
    print('6. View Attendance');
    print('7. Mark Attendance');
    print('8. Exit');

    String? choice = stdin.readLineSync();

    if (choice == '1') {
      print('Enter event title:');
      String title = stdin.readLineSync()!;
      print('Enter event date (YYYY-MM-DD):');
      DateTime date = DateTime.parse(stdin.readLineSync()!);
      print('Enter event time (HH:MM):');
      String time = stdin.readLineSync()!;
      print('Enter event location:');
      String location = stdin.readLineSync()!;
      print('Enter event description:');
      String description = stdin.readLineSync()!;

      Event newEvent = Event(
          title: title, date: date, time: time, location: location, description: description);

      if (scheduler.hasConflict(newEvent)) {
        print('Conflict detected! Event overlaps with an existing event.');
      } else {
        events.add(newEvent);
        await storage.saveEvents(events);
        print('Event added successfully.');
      }
    } else if (choice == '2') {
      print('Upcoming Events:');
      for (var event in scheduler.getEventsInChronologicalOrder()) {
        if (event.date.isAfter(DateTime.now())) {
          print(event);
        }
      }

      print('\nPast Events:');
      for (var event in scheduler.getEventsInChronologicalOrder()) {
        if (event.date.isBefore(DateTime.now())) {
          print(event);
        }
      }
    } else if (choice == '3') {
      print('Enter the title of the event to edit:');
      String oldTitle = stdin.readLineSync()!;
      Event? eventToEdit = events.firstWhere(
          (event) => event.title == oldTitle,
          orElse: () => Event(title: '', date: DateTime(0000), time: '', location: '', description: ''));

      if (eventToEdit.title.isNotEmpty) {
        print('Enter new title:');
        String title = stdin.readLineSync()!;
        if (title.isNotEmpty) eventToEdit.title = title;

        print('Enter new date (YYYY-MM-DD):');
        String dateStr = stdin.readLineSync()!;
        if (dateStr.isNotEmpty) eventToEdit.date = DateTime.parse(dateStr);

        print('Enter new time (HH:MM):');
        String time = stdin.readLineSync()!;
        if (time.isNotEmpty) eventToEdit.time = time;

        print('Enter new location:');
        String location = stdin.readLineSync()!;
        if (location.isNotEmpty) eventToEdit.location = location;

        print('Enter new description:');
        String description = stdin.readLineSync()!;
        if (description.isNotEmpty) eventToEdit.description = description;

        await storage.saveEvents(events);
        print('Event updated successfully.');
      } else {
        print('Event not found.');
      }
    } else if (choice == '4') {
      print('Enter the title of the event to delete:');
      String title = stdin.readLineSync()!;
      events.removeWhere((event) => event.title == title);

      await storage.saveEvents(events);
      print('Event deleted successfully.');
    } else if (choice == '5') {
      print('Enter event title to register attendance:');
      String eventTitle = stdin.readLineSync()!;
      print('Enter attendee name:');
      String attendeeName = stdin.readLineSync()!;

      Attendance attendance = await storage.loadAttendance(eventTitle);
      if (!attendance.attendees.contains(attendeeName)) {
        attendance.attendees.add(attendeeName);
        attendance.presence[attendeeName] = AttendanceStatus.absent;
        await storage.saveAttendance(eventTitle, attendance);
        print('Attendee $attendeeName registered for event $eventTitle.');
      } else {
        print('Attendee already registered.');
      }
    } else if (choice == '6') {
      print('Enter event title to view attendance:');
      String eventTitle = stdin.readLineSync()!;

      Attendance attendance = await storage.loadAttendance(eventTitle);
      print('Attendees for $eventTitle:');
      for (var attendee in attendance.attendees) {
        String status = attendance.presence[attendee] == AttendanceStatus.present ? 'Present' : 'Absent';
        print('$attendee: $status');
      }
    } else if (choice == '7') {
      print('Enter event title:');
      String eventTitle = stdin.readLineSync()!;
      print('Enter attendee name:');
      String attendeeName = stdin.readLineSync()!;
      print('Mark as (present/absent):');
      String status = stdin.readLineSync()!;
      AttendanceStatus isPresent = status.toLowerCase() == 'present'
          ? AttendanceStatus.present
          : AttendanceStatus.absent;

      Attendance attendance = await storage.loadAttendance(eventTitle);
      if (attendance.attendees.contains(attendeeName)) {
        attendance.presence[attendeeName] = isPresent;
        await storage.saveAttendance(eventTitle, attendance);
        print('Attendance status updated for $attendeeName.');
      } else {
        print('Attendee not found.');
      }
    } else if (choice == '8') {
      print('Exiting...');
      break;
    } else {
      print('Invalid choice. Please try again.');
    }
  }
}
