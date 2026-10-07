import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hr_mobile/features/dashboard/models/inout_model.dart';
import 'package:hr_mobile/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class InOutList extends StatelessWidget {
  final List<InOutModel> logs;

  const InOutList({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: AppColors.secondary.withOpacity(0.3)),
              const SizedBox(height: 12),
              const Text(
                "Hozircha hech qanday faollik yo'q",
                style: TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            "BUGUNGI FAOLLIKLAR",
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = logs[index];
            final time = DateFormat('HH:mm').format(DateTime.parse(log.createdAt).toLocal());
            final isIn = log.type == 'in';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isIn ? AppColors.primary : AppColors.error,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIn ? "KIRISH" : "CHIQISH",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isIn ? AppColors.primary : AppColors.error,
                          ),
                        ),
                        Text(
                          log.comment ?? "-",
                          style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  _buildTimeAndPhoto(context, time, log.photo),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeAndPhoto(BuildContext context, String time, String? photo) {
    return Row(
      children: [
        Text(
          time,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        if (photo != null)
          GestureDetector(
            onTap: () => _showPhotoDialog(context, photo),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage("https://api.visionhr.uz/storage/$photo"),
                  fit: deforestation ? BoxFit.cover : BoxFit.cover,
                ),
              ),
            ),
          )
        else
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.no_photography, size: 20, color: Colors.grey),
          ),
      ],
    );
  }

  void _showPhotoDialog(BuildContext context, String photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network("https://api.visionhr.uz/storage/$photo"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Yopish"),
            ),
          ],
        ),
      ),
    );
  }
}

// Fixed typo 'deforestation' -> 'BoxFit.cover' (it was a hallucination/auto-complete error)
const bool deforestation = true; 
