import 'package:intl/intl.dart';

abstract class TimeUtils {
  /// Returns current time as HH:mm:ss — sent to punch-in / punch-out API
  static String nowHHmmss() => DateFormat('HH:mm:ss').format(DateTime.now());

  /// Formats HH:mm:ss → h:mm a  (e.g. "09:05:00" → "9:05 AM")
  static String fmtTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    try {
      final parts = raw.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(0, 1, 1, h, m);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  /// "3.92" → "3h 55m"
  static String fmtHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Today's date as yyyy-MM-dd
  static String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Formatted display date e.g. "Tuesday, 27 May 2026"
  static String displayDate() =>
      DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
}
