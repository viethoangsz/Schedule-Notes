// utils/date_utils.dart
// Các hàm tiện ích xử lý ngày tháng và thời gian

import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format ngày: "Thứ Hai, 05/06/2026"
  static String formatDateFull(DateTime date) {
    final weekdays = [
      'Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư',
      'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'
    ];
    final weekday = weekdays[date.weekday % 7];
    final formatted = DateFormat('dd/MM/yyyy').format(date);
    return '$weekday, $formatted';
  }

  /// Format ngày ngắn: "05/06/2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format giờ: "14:30"
  static String formatTime(String time) => time;

  /// Format ngày tháng cho header: "Tháng 6, 2026"
  static String formatMonthYear(DateTime date) {
    final months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return '${months[date.month - 1]}, ${date.year}';
  }

  /// Hiển thị thời gian tương đối: "2 giờ trước", "Vừa xong"
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Kiểm tra ngày có phải hôm nay không
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Kiểm tra ngày có phải ngày mai không
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Hiển thị ngày thân thiện: "Hôm nay", "Ngày mai", hoặc ngày cụ thể
  static String friendlyDate(DateTime date) {
    if (isToday(date)) return 'Hôm nay';
    if (isTomorrow(date)) return 'Ngày mai';
    return formatDate(date);
  }

  /// Parse time string "HH:mm" thành TimeOfDay
  static Map<String, int>? parseTime(String? timeStr) {
    if (timeStr == null) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    return {
      'hour': int.tryParse(parts[0]) ?? 0,
      'minute': int.tryParse(parts[1]) ?? 0,
    };
  }

  /// Format TimeOfDay thành string "HH:mm"
  static String formatTimeOfDay(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
