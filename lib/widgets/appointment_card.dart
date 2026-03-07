import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
  });

  final Appointment appointment;

  Color _statusColor() {
    switch (appointment.status) {
      case AppointmentStatus.upcoming:
        return AppTheme.deepBlue;
      case AppointmentStatus.completed:
        return const Color(0xFF3BD16F);
      case AppointmentStatus.cancelled:
        return const Color(0xFFE06C75);
    }
  }

  String _statusLabel() {
    switch (appointment.status) {
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'DR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.skyBlue.withOpacity(0.2),
                child: Text(
                  _initialsFor(appointment.doctorName),
                  style: textTheme.labelLarge?.copyWith(
                    color: AppTheme.deepBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.doctorName, style: textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      appointment.specialty,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(),
                  style: textTheme.labelSmall?.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  appointment.timeLabel,
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (appointment.status == AppointmentStatus.upcoming)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      appointment.mode == AppointmentMode.video
                          ? Icons.videocam_rounded
                          : Icons.local_hospital_rounded,
                      size: 18,
                    ),
                    label: Text(
                      appointment.mode == AppointmentMode.video
                          ? 'Video Call'
                          : 'In Person',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepBlue,
                      side: const BorderSide(color: AppTheme.border),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: AppTheme.deepBlue,
                    ),
                    child: const Text('Join Now'),
                  ),
                ),
              ],
            )
          else
            Text(
              appointment.status == AppointmentStatus.completed
                  ? 'Session completed'
                  : 'Session cancelled',
              style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }
}
