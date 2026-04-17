class UserProfile {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String gender;
  final int age;
  final int heightCm;
  final DateTime? birthDate;
  final String morphology;
  final List<String> preferredStyles;

  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.birthDate,
    required this.morphology,
    required this.preferredStyles,
  });

  factory UserProfile.defaults() {
    return const UserProfile(
      userId: 'local-user',
      displayName: 'Utilisateur',
      avatarUrl: '',
      gender: 'Non précise',
      age: 25,
      heightCm: 170,
      birthDate: null,
      morphology: 'Silhouette non définie',
      preferredStyles: ['Casual'],
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final birthDateRaw = json['birthDate'];
    DateTime? birthDate;
    if (birthDateRaw is String && birthDateRaw.isNotEmpty) {
      birthDate = DateTime.tryParse(birthDateRaw);
    }

    return UserProfile(
      userId: json['userId'] as String? ?? 'local-user',
      displayName: json['displayName'] as String? ?? 'Utilisateur',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Non précise',
      age: json['age'] as int? ?? 25,
      heightCm: json['heightCm'] as int? ?? 170,
      birthDate: birthDate,
      morphology: json['morphology'] as String? ?? 'Silhouette non définie',
      preferredStyles: (json['preferredStyles'] as List<dynamic>? ?? ['Casual'])
          .map((style) => style.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'age': age,
      'heightCm': heightCm,
      'birthDate': birthDate?.toIso8601String(),
      'morphology': morphology,
      'preferredStyles': preferredStyles,
    };
  }

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? gender,
    int? age,
    int? heightCm,
    DateTime? birthDate,
    String? morphology,
    List<String>? preferredStyles,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      birthDate: birthDate ?? this.birthDate,
      morphology: morphology ?? this.morphology,
      preferredStyles: preferredStyles ?? this.preferredStyles,
    );
  }
}
