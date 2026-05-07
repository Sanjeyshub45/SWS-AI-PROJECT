// lib/core/utils/file_size_formatter.dart

class FileSizeFormatter {
  /// Converts bytes to a human-readable string (B / KB / MB / GB).
  static String format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  /// Returns the percentage of [bytes] relative to [totalBytes], as a string.
  static String percent(int bytes, int totalBytes) {
    if (totalBytes == 0) return '0%';
    return '${((bytes / totalBytes) * 100).toInt()}%';
  }
}
