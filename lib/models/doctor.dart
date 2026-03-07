class Doctor {
  const Doctor({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.isOnline,
    required this.nextAvailable,
  });

  final String name;
  final String specialty;
  final double rating;
  final bool isOnline;
  final String nextAvailable;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'DR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
