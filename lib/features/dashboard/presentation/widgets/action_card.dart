import 'package:flutter/material.dart';
import 'package:hr_mobile/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionCard extends StatelessWidget {
  final int onWorkStatus;
  final Map<String, dynamic>? details;
  final VoidCallback onAction;
  final bool isLoading;

  const ActionCard({
    super.key,
    required this.onWorkStatus,
    this.details,
    required this.onAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = details?['employee_schedule'];
    final startTime = schedule?['start_time'];
    final todayWorkDay = details?['today_work_day'];
    final isOff = todayWorkDay != null && (todayWorkDay as List).isNotEmpty &&
        (todayWorkDay[0]['type'] == 'off' || todayWorkDay[0]['type'] == 'holiday');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ish holati",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: onWorkStatus == 1 ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    onWorkStatus == 1 ? "Ishlamoqda" : (isOff ? "Dam olish" : "Ishga kelmagan"),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: onWorkStatus == 1 ? AppColors.success : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildActionButton(),
            const SizedBox(height: 12),
            Text(
              onWorkStatus != 1 
                  ? "Ish boshlash uchun tugmani bosing. Masofa va yuzingiz tekshiriladi."
                  : "Ish kunini yakunlash uchun tugmani bosing.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final isWorking = onWorkStatus == 1;
    final gradient = isWorking 
        ? const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFF43F5E)])
        : AppColors.primaryGradient;

    final disabledGradient = LinearGradient(
      colors: [Colors.grey.shade400, Colors.grey.shade500],
    );

    return InkWell(
      onTap: isLoading ? null : onAction,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: isLoading ? disabledGradient : gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: (isWorking ? AppColors.error : AppColors.primary).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "KAMERA OCHILMOQDA...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ] else ...[
              Icon(isWorking ? Icons.stop : Icons.play_arrow, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                isWorking ? "ISHNI YAKUNLASH" : "ISHNI BOSHLASH",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
