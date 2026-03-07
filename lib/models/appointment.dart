enum AppointmentStatus { upcoming, completed, cancelled }

enum AppointmentMode { video, inPerson }

class Appointment {
  const Appointment({
    required this.doctorName,
    required this.specialty,
    required this.timeLabel,
    required this.status,
    required this.mode,
  });

  final String doctorName;
  final String specialty;
  final String timeLabel;
  final AppointmentStatus status;
  final AppointmentMode mode;
}
