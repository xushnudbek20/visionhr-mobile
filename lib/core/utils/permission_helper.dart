import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Checks if location permission is granted.
  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Requests location permission.
  static Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  /// Checks if camera permission is granted.
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Requests camera permission.
  static Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  /// Opens app settings if permission is permanently denied.
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
