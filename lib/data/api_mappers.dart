import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/vital_stat.dart';
import 'package:intl/intl.dart';

List<VitalStat> vitalsFromStats(Map<String, dynamic> stats) {
  final activePatients = stats['activePatients'] ?? stats['active_patients'];
  final todayVisits = stats['todayVisits'] ?? stats['today_visits'];
  final upcomingConsultations =
      stats['upcomingConsultations'] ?? stats['upcoming_consultations'];
  final criticalCases = stats['criticalCases'] ?? stats['critical_cases'];

  final result = <VitalStat>[];

  if (activePatients != null) {
    result.add(VitalStat(
      title: 'Active Patients',
      value: activePatients.toString(),
      unit: 'patients',
      trendLabel: 'Realtime',
    ));
  }
  if (todayVisits != null) {
    result.add(VitalStat(
      title: 'Today Visits',
      value: todayVisits.toString(),
      unit: 'visits',
      trendLabel: 'Today',
    ));
  }
  if (upcomingConsultations != null) {
    result.add(VitalStat(
      title: 'Upcoming',
      value: upcomingConsultations.toString(),
      unit: 'consults',
      trendLabel: 'Scheduled',
    ));
  }
  if (criticalCases != null) {
    result.add(VitalStat(
      title: 'Critical Cases',
      value: criticalCases.toString(),
      unit: 'cases',
      trendLabel: 'High',
    ));
  }

  return result;
}

AppointmentStatus statusFromApi(String? value) {
  switch (value) {
    case 'completed':
      return AppointmentStatus.completed;
    case 'cancelled':
    case 'rejected':
      return AppointmentStatus.cancelled;
    case 'scheduled':
    case 'approved':
    case 'pending':
    default:
      return AppointmentStatus.upcoming;
  }
}

AppointmentMode modeFromApi(String? value) {
  switch (value) {
    case 'virtual':
      return AppointmentMode.video;
    case 'in_person':
    default:
      return AppointmentMode.inPerson;
  }
}

String _labelFromDate(dynamic value) {
  if (value == null) return 'TBD';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return DateFormat('MMM dd, yyyy').format(parsed);
}

Appointment appointmentFromRequest(Map<String, dynamic> json) {
  final status = statusFromApi(json['status']?.toString());
  final mode = modeFromApi(json['visit_mode']?.toString() ?? json['visitMode']?.toString());

  final doctorName =
      json['doctorName'] ?? json['doctor_name'] ?? json['assigned_doctor_name'];
  final patientFirst = json['patient_first_name'] ?? json['patientFirstName'];
  final patientLast = json['patient_last_name'] ?? json['patientLastName'];

  String resolvedName = 'Care Team';
  if (doctorName != null && doctorName.toString().trim().isNotEmpty) {
    resolvedName = doctorName.toString();
  } else if (patientFirst != null || patientLast != null) {
    resolvedName = '${patientFirst ?? ''} ${patientLast ?? ''}'.trim();
    if (resolvedName.isEmpty) resolvedName = 'Care Team';
  }

  final requestType = json['request_type'] ?? json['requestType'];
  final specialty = requestType?.toString() ?? 'General Care';

  final timeLabel = _labelFromDate(
        json['preferred_date'] ?? json['preferredDate'],
      ) !=
          'TBD'
      ? _labelFromDate(json['preferred_date'] ?? json['preferredDate'])
      : _labelFromDate(json['scheduled_time'] ?? json['scheduledTime'] ?? json['created_at']);

  return Appointment(
    doctorName: resolvedName,
    specialty: specialty,
    timeLabel: timeLabel,
    status: status,
    mode: mode,
  );
}

Doctor doctorFromOrgUser(Map<String, dynamic> json) {
  final first = json['first_name'] ?? json['firstName'];
  final last = json['last_name'] ?? json['lastName'];
  final username = json['username'] ?? json['email'] ?? 'Doctor';

  String name = '${first ?? ''} ${last ?? ''}'.trim();
  if (name.isEmpty) name = username.toString();

  final role = json['org_role'] ?? json['orgRole'] ?? json['role'];
  final specialty = role?.toString().replaceAll('_', ' ') ?? 'Medical Professional';

  return Doctor(
    name: name,
    specialty: _capitalize(specialty),
    rating: 4.8,
    isOnline: true,
    nextAvailable: 'Available today',
  );
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value
      .split(' ')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
