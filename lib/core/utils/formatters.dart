//centralized formatter class to maintain dates, amounts, and time

class Formatters {
  Formatters._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // 1234567 -> "1,234,567"
  static String number(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  // 48200000 -> "Rs. 48.2M"
  static String currencyCompact(double v) {
    if (v >= 1e9) return 'Rs. ${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return 'Rs. ${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return 'Rs. ${(v / 1e3).toStringAsFixed(0)}K';
    return 'Rs. ${v.toStringAsFixed(0)}';
  }

  static String currencyFull(double v) => 'Rs. ${number(v)}';

  static String shortDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}