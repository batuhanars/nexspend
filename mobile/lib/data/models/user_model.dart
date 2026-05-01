class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.currency,
    required this.language,
    required this.biometricEnabled,
    required this.notificationsEnabled,
    this.avatarUrl,
    required this.hasPassword,
    required this.isGoogleLinked,
  });

  final String id;
  final String fullName;
  final String email;
  final String currency;
  final String language;
  final bool biometricEnabled;
  final bool notificationsEnabled;
  final String? avatarUrl;
  final bool hasPassword;
  final bool isGoogleLinked;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        currency: json['currency'] as String? ?? 'TRY',
        language: json['language'] as String? ?? 'tr',
        biometricEnabled: json['biometricEnabled'] as bool? ?? false,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        avatarUrl: json['avatarUrl'] as String?,
        hasPassword: json['hasPassword'] as bool? ?? true,
        isGoogleLinked: json['isGoogleLinked'] as bool? ?? false,
      );

  UserModel copyWith({
    String? fullName,
    String? currency,
    String? language,
    bool? biometricEnabled,
    bool? notificationsEnabled,
    String? avatarUrl,
    bool clearAvatar = false,
  }) =>
      UserModel(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        currency: currency ?? this.currency,
        language: language ?? this.language,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
        hasPassword: hasPassword,
        isGoogleLinked: isGoogleLinked,
      );
}
