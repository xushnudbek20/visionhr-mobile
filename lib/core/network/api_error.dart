import 'package:dio/dio.dart';

/// Dio xatoliklarini foydalanuvchiga tushunarli o'zbekcha matnga aylantiradi.
String apiErrorMessage(Object error) {
  if (error is String) return error;
  if (error is! DioException) return 'Kutilmagan xatolik yuz berdi';

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return 'Serverga ulanib bo\'lmadi. Internetingizni tekshirib, qayta urinib ko\'ring';
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Internet sekin ishlayapti. Qayta urinib ko\'ring';
    case DioExceptionType.connectionError:
      return 'Internetga ulanish yo\'q. Aloqani tekshiring';
    case DioExceptionType.cancel:
      return 'So\'rov bekor qilindi';
    case DioExceptionType.badCertificate:
      return 'Xavfsiz ulanishda muammo yuz berdi';
    case DioExceptionType.badResponse:
      return _badResponseMessage(error);
    case DioExceptionType.unknown:
      return 'Server bilan bog\'lanishda xatolik. Qayta urinib ko\'ring';
  }
}

String _badResponseMessage(DioException error) {
  final data = error.response?.data;
  final statusCode = error.response?.statusCode;

  if (data is Map) {
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      if (firstError is String) return firstError;
    }
    final message = data['message'];
    if (message != null) return message.toString();
  }

  switch (statusCode) {
    case 401:
      return 'Sessiya muddati tugagan. Qaytadan kiring';
    case 403:
      return 'Bu amalni bajarishga ruxsatingiz yo\'q';
    case 404:
      return 'Ma\'lumot topilmadi';
    case 413:
      return 'Rasm hajmi juda katta';
    case 429:
      return 'Juda ko\'p urinish. Biroz kutib turing';
    default:
      if (statusCode != null && statusCode >= 500) {
        return 'Serverda xatolik yuz berdi. Birozdan so\'ng urinib ko\'ring';
      }
      return 'Xatolik yuz berdi${statusCode != null ? ' ($statusCode)' : ''}';
  }
}

/// Timeout/ulanish xatoliklarida davomat serverga yozilgan bo'lishi mumkin —
/// bunday holatda foydalanuvchiga holatni yangilashni taklif qilamiz.
bool isNetworkTimeout(Object error) {
  if (error is! DioException) return false;
  return error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.unknown;
}
