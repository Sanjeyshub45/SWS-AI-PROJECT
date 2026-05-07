// lib/core/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _dateTimeFormat = DateFormat('MMM d, h:mm a');
  static final _shortFormat = DateFormat('dd/MM/yy');

  /// e.g.  "May 7, 2026"
  static String date(DateTime dt) => _dateFormat.format(dt);

  /// e.g.  "May 7, 2:30 PM"
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt);

  /// e.g.  "07/05/26"
  static String short(DateTime dt) => _shortFormat.format(dt);

  /// Returns a human-friendly relative label: "Just now", "2 min ago", etc.
  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _dateFormat.format(dt);
  }
}
