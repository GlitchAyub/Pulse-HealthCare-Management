class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.username,
    this.organizationId,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role;
  final String? username;
  final String? organizationId;

  factory User.fromJson(Map<String, dynamic> json) {
    String? stringValue(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final text = value.toString();
        if (text.isNotEmpty) return text;
      }
      return null;
    }

    return User(
      id: stringValue(const ['id']) ?? '',
      email: stringValue(const ['email']) ?? '',
      firstName: stringValue(const ['firstName', 'first_name']),
      lastName: stringValue(const ['lastName', 'last_name']),
      role: stringValue(const ['role']) ?? 'patient',
      username: stringValue(const ['username']),
      organizationId: stringValue(const ['organizationId', 'organization_id']),
    );
  }
}
