import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/vital_stat.dart';

const mockVitals = [
  VitalStat(title: 'Heart Rate', value: '98', unit: 'bpm', trendLabel: 'Stable'),
  VitalStat(title: 'Blood Pressure', value: '120/80', unit: 'mmHg', trendLabel: 'Normal'),
];

const mockDoctors = [
  Doctor(
    name: 'Dr. Michael Chen',
    specialty: 'Cardiologist',
    rating: 4.9,
    isOnline: true,
    nextAvailable: 'Today, 10:00 AM',
  ),
  Doctor(
    name: 'Dr. Sarah Johnson',
    specialty: 'Cardiologist',
    rating: 4.8,
    isOnline: true,
    nextAvailable: 'Today, 12:30 PM',
  ),
  Doctor(
    name: 'Dr. BKO Johnson',
    specialty: 'Neurologist',
    rating: 4.7,
    isOnline: false,
    nextAvailable: 'Tomorrow, 9:00 AM',
  ),
];

const mockAppointments = [
  Appointment(
    doctorName: 'Dr. Michael Chen',
    specialty: 'Cardiologist',
    timeLabel: 'Today, 10:00 AM',
    status: AppointmentStatus.upcoming,
    mode: AppointmentMode.video,
  ),
  Appointment(
    doctorName: 'Dr. Sarah Johnson',
    specialty: 'Cardiologist',
    timeLabel: 'Today, 1:00 PM',
    status: AppointmentStatus.upcoming,
    mode: AppointmentMode.inPerson,
  ),
  Appointment(
    doctorName: 'Dr. Emma Davis',
    specialty: 'Pediatrics',
    timeLabel: 'Mar 02, 2026',
    status: AppointmentStatus.completed,
    mode: AppointmentMode.video,
  ),
  Appointment(
    doctorName: 'Dr. Raj Patel',
    specialty: 'Neurologist',
    timeLabel: 'Jan 18, 2026',
    status: AppointmentStatus.cancelled,
    mode: AppointmentMode.inPerson,
  ),
];
