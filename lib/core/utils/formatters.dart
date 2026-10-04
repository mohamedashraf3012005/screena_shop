// تنسيق العملة والأرقام
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {int decimalPlaces = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalPlaces}', 'ar');
    return '${formatter.format(amount)} ج';
  }

  static String formatSimple(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return formatter.format(amount);
  }

  static String formatInt(int amount) {
    final formatter = NumberFormat('#,##0', 'ar');
    return formatter.format(amount);
  }
}

class DateFormatter {
  static String format(DateTime date) {
    return DateFormat('yyyy/MM/dd', 'ar').format(date);
  }

  static String formatWithTime(DateTime date) {
    return DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'ar').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'الآن';
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays == 1) {
      return 'أمس';
    }
    return format(date);
  }
}
