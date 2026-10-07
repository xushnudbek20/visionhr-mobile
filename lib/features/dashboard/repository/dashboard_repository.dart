import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/inout_model.dart';
import '../../auth/models/user_model.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<Map<String, dynamic>> getUserDetails(int userId) async {
    try {
      final response = await _dio.get('/settings/users/$userId', queryParameters: {
        'relations': 'locations|todayWorkDay|location|warehouse|employeeSchedule',
      });
      return Map<String, dynamic>.from(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<InOutModel>> getAttendanceLogs({
    required int userId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await _dio.get('/hr/in-outs', queryParameters: {
        'user_id': userId,
        'from_date': fromDate,
        'to_date': toDate,
      });
      final rawData = response.data['data'];
      final List data = rawData is Map ? (rawData['data'] ?? []) : (rawData ?? []);
      return data.map((json) => InOutModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitAttendance({
    required String type,
    required int locationId,
    required String photoBase64,
    String? comment,
  }) async {
    final formData = FormData.fromMap({
      'type': type,
      'location_id': locationId.toString(),
      'photo': MultipartFile.fromBytes(
        base64Decode(photoBase64),
        filename: 'photo.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
      if (comment != null) 'comment': comment,
    });

    // Rasm yuborish sekin internetda uzoq davom etishi mumkin —
    // shu so'rov uchun timeout kattaroq.
    await _dio.post(
      '/hr/in-outs',
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }
}
