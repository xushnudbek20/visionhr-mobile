import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hr_mobile/core/network/api_error.dart';
import 'package:hr_mobile/features/dashboard/repository/dashboard_repository.dart';
import 'package:hr_mobile/features/dashboard/presentation/dashboard_provider.dart';

/// Liveness detection phases mirroring the web front-end flow
enum LivenessPhase {
  initializing,
  detectingFace,
  checkingHeadRight,
  checkingHeadCenter,
  checkingStability,
  capturing,
  uploading,
  complete,
  error,
}

class LivenessState {
  final bool isInitializing;
  final bool isProcessing;
  final String? message;
  final bool success;
  final LivenessPhase phase;
  final bool isFaceDetected;
  final bool headTurnedRight;
  final bool headReturnedCenter;
  final bool isStable;

  LivenessState({
    this.isInitializing = true,
    this.isProcessing = false,
    this.message,
    this.success = false,
    this.phase = LivenessPhase.initializing,
    this.isFaceDetected = false,
    this.headTurnedRight = false,
    this.headReturnedCenter = false,
    this.isStable = false,
  });

  LivenessState copyWith({
    bool? isInitializing,
    bool? isProcessing,
    String? message,
    bool? success,
    LivenessPhase? phase,
    bool? isFaceDetected,
    bool? headTurnedRight,
    bool? headReturnedCenter,
    bool? isStable,
  }) {
    return LivenessState(
      isInitializing: isInitializing ?? this.isInitializing,
      isProcessing: isProcessing ?? this.isProcessing,
      message: message,
      success: success ?? this.success,
      phase: phase ?? this.phase,
      isFaceDetected: isFaceDetected ?? this.isFaceDetected,
      headTurnedRight: headTurnedRight ?? this.headTurnedRight,
      headReturnedCenter: headReturnedCenter ?? this.headReturnedCenter,
      isStable: isStable ?? this.isStable,
    );
  }
}

class LivenessNotifier extends StateNotifier<LivenessState> {
  final DashboardRepository _repository;
  final Ref _ref;
  CameraController? _cameraController;
  bool _isDetecting = false;
  bool _autoCaptureTriggered = false;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  // Timers for phase transitions
  Timer? _faceDetectedTimer;
  DateTime? _stabilityStart;
  double? _lastNoseOffsetX;
  double? _lastNoseOffsetY;

  static const _stabilityDurationMs = 800;
  static const _headTurnThreshold = 0.15; // nose offset ratio threshold

  LivenessNotifier(this._repository, this._ref) : super(LivenessState());

  CameraController? get controller => _cameraController;

  Future<void> initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      state = state.copyWith(
        isInitializing: false,
        message: "Kamera ruxsati berilmadi",
        phase: LivenessPhase.error,
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      state = state.copyWith(
        isInitializing: false,
        phase: LivenessPhase.detectingFace,
        message: "Yuzingizni ramkaga joylashtiring",
      );

      // Start image stream for face detection
      _startImageStream();
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        message: "Kamera xatosi: ${e.toString()}",
        phase: LivenessPhase.error,
      );
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isDetecting &&
          !state.success &&
          state.phase != LivenessPhase.capturing &&
          state.phase != LivenessPhase.uploading &&
          state.phase != LivenessPhase.complete) {
        _processImage(image);
      }
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isDetecting || !mounted) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isEmpty) {
        _onNoFace();
      } else {
        _onFaceDetected(faces.first, image.width, image.height);
      }
    } catch (e) {
      // Silently skip frame errors
      debugPrint('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      // Front camera on Android: rotation = (sensorOrientation + 360) % 360
      // with front camera mirroring
      final rotationCompensation = sensorOrientation;
      rotation = _intToRotation(rotationCompensation);
    } else {
      rotation = _intToRotation(sensorOrientation);
    }

    if (rotation == null) return null;

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    // For NV21, concatenate all planes into one
    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: allBytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation? _intToRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void _onNoFace() {
    if (!mounted) return;
    _faceDetectedTimer?.cancel();
    _faceDetectedTimer = null;
    _stabilityStart = null;

    if (state.phase == LivenessPhase.detectingFace ||
        state.phase == LivenessPhase.checkingHeadRight ||
        state.phase == LivenessPhase.checkingHeadCenter ||
        state.phase == LivenessPhase.checkingStability) {
      state = state.copyWith(
        isFaceDetected: false,
        message: "Yuzingizni ramkaga joylashtiring",
        phase: LivenessPhase.detectingFace,
        headTurnedRight: false,
        headReturnedCenter: false,
        isStable: false,
      );
    }
  }

  void _onFaceDetected(Face face, int imageWidth, int imageHeight) {
    if (!mounted) return;

    state = state.copyWith(isFaceDetected: true);

    switch (state.phase) {
      case LivenessPhase.detectingFace:
        _handleDetectingFace(face);
        break;
      case LivenessPhase.checkingHeadRight:
        _handleCheckingHeadRight(face, imageWidth);
        break;
      case LivenessPhase.checkingHeadCenter:
        _handleCheckingHeadCenter(face, imageWidth);
        break;
      case LivenessPhase.checkingStability:
        _handleCheckingStability(face, imageWidth, imageHeight);
        break;
      default:
        break;
    }
  }

  void _handleDetectingFace(Face face) {
    state = state.copyWith(
      message: "Yuz aniqlandi! Tayyorlanmoqda...",
    );

    if (_faceDetectedTimer == null) {
      _faceDetectedTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && state.isFaceDetected) {
          state = state.copyWith(
            phase: LivenessPhase.checkingHeadRight,
            message: "Boshingizni o'ngga buring",
          );
        }
        _faceDetectedTimer = null;
      });
    }
  }

  void _handleCheckingHeadRight(Face face, int imageWidth) {
    // Use headEulerAngleY: negative = turned right (user's right in mirrored view)
    final headY = face.headEulerAngleY ?? 0.0;

    // Also use landmark-based offset as fallback
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    bool turnedRight = false;

    // Primary: Euler angle check — turned right means headY < -15 degrees
    if (headY < -15.0) {
      turnedRight = true;
    }

    // Fallback: landmark offset check
    if (!turnedRight && noseBase != null && leftEye != null && rightEye != null) {
      final eyeMidX = (leftEye.position.x + rightEye.position.x) / 2.0;
      final interEyeDist = (rightEye.position.x - leftEye.position.x).abs().toDouble();
      if (interEyeDist > 0) {
        final offset = (noseBase.position.x - eyeMidX) / interEyeDist;
        // Negative offset = nose shifted left in image = user turned right (front camera mirrored)
        if (offset < -_headTurnThreshold) {
          turnedRight = true;
        }
      }
    }

    if (turnedRight) {
      state = state.copyWith(
        headTurnedRight: true,
        phase: LivenessPhase.checkingHeadCenter,
        message: "Zo'r! Endi kameraga to'g'ri qarang",
      );
    } else {
      state = state.copyWith(message: "Boshingizni o'ngga buring");
    }
  }

  void _handleCheckingHeadCenter(Face face, int imageWidth) {
    final headY = face.headEulerAngleY ?? 0.0;

    bool centered = false;

    // Primary: Euler angle near zero
    if (headY.abs() < 10.0) {
      centered = true;
    }

    // Fallback: landmark check
    if (!centered) {
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      if (noseBase != null && leftEye != null && rightEye != null) {
        final eyeMidX = (leftEye.position.x + rightEye.position.x) / 2.0;
        final interEyeDist = (rightEye.position.x - leftEye.position.x).abs().toDouble();
        if (interEyeDist > 0) {
          final offset = ((noseBase.position.x - eyeMidX) / interEyeDist).abs();
          if (offset < 0.1) {
            centered = true;
          }
        }
      }
    }

    if (centered) {
      _stabilityStart = null;
      state = state.copyWith(
        headReturnedCenter: true,
        phase: LivenessPhase.checkingStability,
        message: "Iltimos, harakatsiz turing...",
      );
    } else {
      state = state.copyWith(message: "Kameraga to'g'ri qarang");
    }
  }

  void _handleCheckingStability(Face face, int imageWidth, int imageHeight) {
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    if (noseBase == null) {
      _stabilityStart = null;
      return;
    }

    final noseX = noseBase.position.x / imageWidth.toDouble();
    final noseY = noseBase.position.y / imageHeight.toDouble();

    if (_lastNoseOffsetX != null && _lastNoseOffsetY != null) {
      final dx = (noseX - _lastNoseOffsetX!).abs();
      final dy = (noseY - _lastNoseOffsetY!).abs();

      if (dx < 0.02 && dy < 0.02) {
        _stabilityStart ??= DateTime.now();

        final elapsed = DateTime.now().difference(_stabilityStart!).inMilliseconds;
        if (elapsed >= _stabilityDurationMs) {
          state = state.copyWith(
            isStable: true,
            message: "Surat olinmoqda...",
            phase: LivenessPhase.capturing,
          );
          _triggerAutoCapture();
          return;
        } else {
          state = state.copyWith(message: "Harakatsiz turing...");
        }
      } else {
        _stabilityStart = null;
        state = state.copyWith(message: "Iltimos, harakatsiz turing");
      }
    }

    _lastNoseOffsetX = noseX;
    _lastNoseOffsetY = noseY;
  }

  void _triggerAutoCapture() {
    if (_autoCaptureTriggered) return;
    _autoCaptureTriggered = true;

    // Stop image stream before taking picture
    _stopImageStream();

    // Small delay to let the stream fully stop, then capture + submit
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _captureAndSubmit();
      }
    });
  }

  void _stopImageStream() {
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
  }

  String? _pendingType;
  int? _pendingLocationId;

  /// Called from the screen to set type/locationId before starting camera
  void setAttendanceParams({required String type, required int locationId}) {
    _pendingType = type;
    _pendingLocationId = locationId;
  }

  /// Single method: capture photo + submit to API
  Future<void> _captureAndSubmit() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_pendingType == null || _pendingLocationId == null) return;

    state = state.copyWith(
      isProcessing: true,
      message: "Rasm olinmoqda...",
      phase: LivenessPhase.uploading,
    );

    try {
      final XFile photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();
      final base64Photo = base64Encode(bytes);

      state = state.copyWith(message: "Yuborilmoqda...");

      await _repository.submitAttendance(
        type: _pendingType!,
        locationId: _pendingLocationId!,
        photoBase64: base64Photo,
      );

      state = state.copyWith(
        isProcessing: false,
        success: true,
        message: "Muvaffaqiyatli!",
        phase: LivenessPhase.complete,
      );
      _ref.read(dashboardProvider.notifier).refresh();
    } catch (e) {
      // Timeout bo'lsa so'rov serverga yetib borgan bo'lishi mumkin —
      // dashboard'ni yangilaymiz, foydalanuvchi holatini ko'rib qayta uriladi.
      final timedOut = isNetworkTimeout(e);
      if (timedOut) {
        _ref.read(dashboardProvider.notifier).refresh();
      }

      state = state.copyWith(
        isProcessing: false,
        message: timedOut
            ? "${apiErrorMessage(e)}.\nAgar davomat yozilgan bo'lsa, asosiy sahifada ko'rinadi"
            : apiErrorMessage(e),
        phase: LivenessPhase.error,
      );
      _autoCaptureTriggered = false;
    }
  }

  @override
  void dispose() {
    _faceDetectedTimer?.cancel();
    _stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}

final livenessProvider = StateNotifierProvider.autoDispose<LivenessNotifier, LivenessState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return LivenessNotifier(repository, ref);
});
