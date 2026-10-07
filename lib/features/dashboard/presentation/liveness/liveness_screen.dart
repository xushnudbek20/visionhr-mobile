import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_mobile/features/dashboard/presentation/liveness/liveness_provider.dart';
import 'package:hr_mobile/core/constants/app_colors.dart';

class LivenessScreen extends ConsumerStatefulWidget {
  final String type;
  final int locationId;

  const LivenessScreen({
    super.key,
    required this.type,
    required this.locationId,
  });

  @override
  ConsumerState<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends ConsumerState<LivenessScreen> {
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(livenessProvider.notifier);
      notifier.setAttendanceParams(type: widget.type, locationId: widget.locationId);
      notifier.initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livenessProvider);
    final notifier = ref.watch(livenessProvider.notifier);

    if (state.success && !_hasPopped) {
      _hasPopped = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview — preserving aspect ratio
          if (!state.isInitializing && notifier.controller != null)
            Positioned.fill(
              child: _buildCameraPreview(notifier.controller!),
            ),

          // Loading indicator while camera initializes
          if (state.isInitializing)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Kamera tayyorlanmoqda...",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Face guide overlay
          if (!state.isInitializing) _buildFaceOverlay(state),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Phase indicators (top right)
          if (!state.isInitializing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildPhaseIndicators(state),
            ),

          // Instructions at bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24,
            right: 24,
            child: _buildInstructionBanner(state),
          ),

          // Success overlay
          if (state.success)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Muvaffaqiyatli!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.type == 'in' ? "Ishga keldingiz" : "Ishdan chiqdingiz",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the camera preview with correct aspect ratio (no stretching)
  Widget _buildCameraPreview(CameraController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) return const SizedBox.shrink();

        // previewSize is in landscape orientation (width > height), so we swap for portrait
        final cameraAspectRatio = previewSize.height / previewSize.width;
        final screenAspectRatio = constraints.maxWidth / constraints.maxHeight;

        // Use FittedBox + SizedBox to fill the screen while preserving aspect ratio
        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / cameraAspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the face guide overlay — rounded rectangle like the front-end
  Widget _buildFaceOverlay(LivenessState state) {
    Color borderColor;
    if (state.phase == LivenessPhase.checkingStability && state.isStable) {
      borderColor = AppColors.success;
    } else if (state.isFaceDetected) {
      borderColor = AppColors.primary;
    } else {
      borderColor = Colors.white38;
    }

    return Center(
      child: Container(
        width: 260,
        height: 340,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: 3,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(130),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds phase check indicators (right side)
  Widget _buildPhaseIndicators(LivenessState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _phaseChip("Yuz aniqlash", state.isFaceDetected),
        const SizedBox(height: 6),
        _phaseChip("Bosh o'ngga", state.headTurnedRight),
        const SizedBox(height: 6),
        _phaseChip("Markazga qaytish", state.headReturnedCenter),
        const SizedBox(height: 6),
        _phaseChip("Barqarorlik", state.isStable),
      ],
    );
  }

  Widget _phaseChip(String label, bool completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.success.withOpacity(0.2)
            : Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed ? AppColors.success.withOpacity(0.5) : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: completed ? AppColors.success : Colors.white54,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: completed ? Colors.white : Colors.white54,
              fontWeight: completed ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Instruction banner at the bottom
  Widget _buildInstructionBanner(LivenessState state) {
    Color bgColor;
    if (state.success) {
      bgColor = AppColors.success.withOpacity(0.8);
    } else if (state.phase == LivenessPhase.error) {
      bgColor = AppColors.error.withOpacity(0.8);
    } else {
      bgColor = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isProcessing && !state.success)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          Text(
            state.message ?? "Tayyorlanmoqda...",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
