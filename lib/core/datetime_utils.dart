String formatWib(String isoString, {bool withTime = true}) {
  final utc = DateTime.parse(isoString).toUtc();
  final wib = utc.add(const Duration(hours: 7));

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final datePart = '${wib.day} ${months[wib.month - 1]} ${wib.year}';

  if (!withTime) return datePart;

  final hh = wib.hour.toString().padLeft(2, '0');
  final mm = wib.minute.toString().padLeft(2, '0');
  return '$datePart, $hh:$mm WIB';
}