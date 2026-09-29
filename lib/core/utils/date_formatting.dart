import 'package:intl/intl.dart';

String formatDisplayDate(
  DateTime date, {
  required String locale,
  bool includeYear = true,
}) {
  final pattern = includeYear ? 'EEEE d MMMM y' : 'EEEE d MMMM';
  final formatted = DateFormat(pattern, locale).format(date);
  return formatted
      .split(' ')
      .map(
        (part) =>
            part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
      )
      .join(' ');
}

String formatDisplayDateTime(
  DateTime dateTime, {
  required String locale,
  bool includeYear = true,
}) {
  return '${formatDisplayDate(dateTime, locale: locale, includeYear: includeYear)} · ${DateFormat.Hm(locale).format(dateTime)}';
}
