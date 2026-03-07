import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/doctor.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.doctor,
    this.onFavorite,
  });

  final Doctor doctor;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.skyBlue.withOpacity(0.2),
                    child: Text(
                      doctor.initials,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppTheme.deepBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: doctor.isOnline
                            ? const Color(0xFF3BD16F)
                            : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: onFavorite,
                icon: const Icon(Icons.favorite_border_rounded),
                color: AppTheme.periwinkle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(doctor.name, style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            doctor.specialty,
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFC857), size: 18),
              const SizedBox(width: 4),
              Text(doctor.rating.toStringAsFixed(1),
                  style: textTheme.labelLarge),
              const Spacer(),
              Text(
                doctor.nextAvailable,
                style: textTheme.labelSmall?.copyWith(
                  color: AppTheme.deepBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
