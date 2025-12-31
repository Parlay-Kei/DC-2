import 'package:intl/intl.dart';

/// Formatting utilities for display
class Formatters {
  Formatters._();

  // Date formats
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _dateTimeFormat = DateFormat('MMM d, yyyy h:mm a');
  static final _timeFormat = DateFormat('h:mm a');
  static final _shortDateFormat = DateFormat('MMM d');
  static final _dayFormat = DateFormat('EEEE');
  static final _monthYearFormat = DateFormat('MMMM yyyy');

  /// Format currency (USD)
  static String currency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  /// Format currency without cents
  static String currencyWhole(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount);
  }

  /// Format date (Jan 15, 2024)
  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format date and time (Jan 15, 2024 3:30 PM)
  static String dateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format time (3:30 PM)
  static String time(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format time from string (15:30 -> 3:30 PM)
  static String timeFromString(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final dateTime = DateTime(2000, 1, 1, hour, minute);
    return _timeFormat.format(dateTime);
  }

  /// Format short date (Jan 15)
  static String shortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format day name (Monday)
  static String dayName(DateTime date) {
    return _dayFormat.format(date);
  }

  /// Format month and year (January 2024)
  static String monthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format relative time (2h ago, Yesterday, etc)
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    }
    if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}mo ago';
    }
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Format duration (1h 30m, 45m, etc)
  static String duration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (mins == 0) {
      return '${hours}h';
    }

    return '${hours}h ${mins}m';
  }

  /// Format distance (0.5 mi, 2.3 mi, etc)
  static String distance(double miles) {
    if (miles < 0.1) {
      return '< 0.1 mi';
    }
    if (miles < 10) {
      return '${miles.toStringAsFixed(1)} mi';
    }
    return '${miles.round()} mi';
  }

  /// Format phone number
  static String phone(String phone) {
    // Remove all non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // US format: (XXX) XXX-XXXX
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    // With country code: +1 (XXX) XXX-XXXX
    if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }

    return phone;
  }

  /// Format rating (4.5 -> "4.5")
  static String rating(double rating) {
    if (rating == rating.roundToDouble()) {
      return rating.toInt().toString();
    }
    return rating.toStringAsFixed(1);
  }

  /// Format compact number (1.2K, 3.5M, etc)
  static String compactNumber(int number) {
    return NumberFormat.compact().format(number);
  }

  /// Format percentage
  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  /// Format file size (1.2 MB, 500 KB, etc)
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Format initials from name
  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Format booking status
  static String bookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }
}

/// Extension for DateTime formatting
extension DateTimeFormatting on DateTime {
  String get formatted => Formatters.date(this);
  String get formattedDateTime => Formatters.dateTime(this);
  String get formattedTime => Formatters.time(this);
  String get timeAgo => Formatters.relativeTime(this);
  String get dayName => Formatters.dayName(this);
}

/// Extension for double formatting
extension DoubleFormatting on double {
  String get asCurrency => Formatters.currency(this);
  String get asDistance => Formatters.distance(this);
  String get asRating => Formatters.rating(this);
}

/// Extension for int formatting
extension IntFormatting on int {
  String get asDuration => Formatters.duration(this);
  String get compact => Formatters.compactNumber(this);
  String get asFileSize => Formatters.fileSize(this);
}
