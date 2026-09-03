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

String formatIndo(String isoString) {
  final date = DateTime.parse(isoString);

  const monthsId = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

  return '${date.day} ${monthsId[date.month - 1]} ${date.year}';
}