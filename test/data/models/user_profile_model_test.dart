import 'package:flutter_test/flutter_test.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';

void main() {
  group('UserProfile', () {
    test('defaults() should return a profile with default values', () {
      final profile = UserProfile.defaults();

      expect(profile.userId, 'local-user');
      expect(profile.displayName, 'Utilisateur');
      expect(profile.gender, 'Non précise');
      expect(profile.age, 25);
      expect(profile.preferredStyles, ['Casual']);
    });

    test('toJson and fromJson should be consistent', () {
      final profile = UserProfile(
        userId: '123',
        displayName: 'John Doe',
        avatarUrl: 'https://avatar.com',
        gender: 'Homme',
        age: 30,
        birthDate: DateTime(1990, 1, 1),
        heightCm: 180,
        morphology: 'Athlétique',
        preferredStyles: ['Business', 'Elegant'],
      );

      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);

      expect(fromJson.userId, profile.userId);
      expect(fromJson.displayName, profile.displayName);
      expect(fromJson.age, profile.age);
      expect(fromJson.heightCm, profile.heightCm);
      expect(fromJson.preferredStyles, profile.preferredStyles);
    });

    test('isDefault should return true for default profile', () {
      final profile = UserProfile.defaults();
      expect(profile.isDefault, isTrue);

      final custom = profile.copyWith(userId: 'user_1');
      // Copied with new ID still has default fields, but isDefault only checks display name, gender, morphology, and styles.
      // Wait, let's check isDefault logic again.
      // displayName == 'Utilisateur' && gender == 'Non précise' && morphology == 'Silhouette non définie' && (preferredStyles.isEmpty || (preferredStyles.length == 1 && preferredStyles.first == 'Casual'))
      expect(custom.isDefault, isTrue);
      
      final reallyCustom = profile.copyWith(displayName: 'Custom');
      expect(reallyCustom.isDefault, isFalse);
    });
   group('fromJson edge cases', () {
      test('should handle string age correctly', () {
        final json = {
          'userId': '1',
          'age': '35',
        };
        final profile = UserProfile.fromJson(json);
        expect(profile.age, 35);
      });
    });
  });
}
