import 'package:flutter/material.dart';
import 'package:hr_mobile/features/auth/models/user_model.dart';
import 'package:hr_mobile/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic>? details;

  const UserCard({super.key, required this.user, this.details});

  @override
  Widget build(BuildContext context) {
    final locationName = details?['locations'] != null && (details!['locations'] as List).isNotEmpty
        ? (details!['locations'] as List).first['name']
        : (details?['location']?['name'] ?? 'Filial biriktirilmagan');
    final schedule = details?['employee_schedule'] ?? details?['employeeSchedule'];
    final timeStr = schedule != null && schedule['start_time'] != null && schedule['end_time'] != null
        ? "${schedule['start_time'].toString().substring(0, 5)} - ${schedule['end_time'].toString().substring(0, 5)}" 
        : "--:-- - --:--";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primaryFixed,
                  backgroundImage: user.photoUrl != null 
                      ? NetworkImage("https://api.visionhr.uz/storage/${user.photoUrl}") 
                      : null,
                  child: user.photoUrl == null 
                      ? const Icon(Icons.person, size: 40, color: AppColors.primary) 
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        user.role?.displayName ?? "Xodim",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.location_on, "Ish joyi", locationName),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.access_time, "Ish grafigi", timeStr),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
