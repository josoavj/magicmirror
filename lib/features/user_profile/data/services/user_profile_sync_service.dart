import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/core/error/app_exception.dart' as app_error;
import 'package:magicmirror/core/error/result.dart';
import 'package:magicmirror/core/error/retry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class UserProfileSyncService with RetryableMixin {
  UserProfileSyncService();

  static const String avatarBucket = 'avatars';

  @override
  RetryConfig get retryConfig => const RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 5),
  );

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<Result<String>> resolveUserId({String? fallback}) async {
    try {
      final client = _client;
      if (client == null) {
        if (fallback != null) {
          return Success(fallback);
        }
        return Failure(
          app_error.AuthException(
            message: 'Supabase not initialized',
            code: 'SUPABASE_NOT_INIT',
          ),
        );
      }

      final userId = client.auth.currentUser?.id ?? fallback;
      if (userId == null) {
        return Failure(
          app_error.AuthException(
            message: 'User not authenticated',
            code: 'NOT_AUTHENTICATED',
          ),
        );
      }

      return Success(userId);
    } catch (e, st) {
      return Failure(
        app_error.UnknownException(
          message: 'Error resolving user ID: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Result<UserProfile>> fetchProfile(String userId) async {
    return withRetryResult(() async {
      try {
        final client = _client;
        if (client == null) {
          return Failure(
            app_error.AuthException(
              message: 'Supabase not initialized',
              code: 'SUPABASE_NOT_INIT',
            ),
          );
        }

        if (userId.isEmpty) {
          return Failure(
            app_error.ValidationException(message: 'User ID cannot be empty'),
          );
        }

        final data = await client
            .from('profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (data == null) {
          return Failure(
            app_error.DatabaseException(
              message: 'Profile not found for user: $userId',
              code: 'NOT_FOUND',
            ),
          );
        }

        final profileJson = {
          'userId': data['user_id'],
          'displayName': data['display_name'],
          'avatarUrl': data['avatar_url'],
          'gender': data['gender'],
          'age': data['age'],
          'heightCm': data['height_cm'],
          'birthDate': data['birth_date'],
          'morphology': data['morphology'],
          'preferredStyles': data['preferred_styles'] ?? <dynamic>[],
        };

        try {
          final profile = UserProfile.fromJson(profileJson);
          return Success(profile);
        } catch (e, st) {
          return Failure(
            app_error.ParseException(
              message: 'Failed to parse profile: $e',
              originalError: e,
              stackTrace: st,
            ),
          );
        }
      } on PostgrestException catch (e, st) {
        return Failure(
          app_error.DatabaseException(
            message: 'Database error: ${e.message}',
            code: e.code,
            originalError: e,
            stackTrace: st,
          ),
        );
      } catch (e, st) {
        if (e is app_error.AppException) return Failure(e);
        return Failure(
          app_error.UnknownException(
            message: 'Unknown error fetching profile: $e',
            originalError: e,
            stackTrace: st,
          ),
        );
      }
    });
  }

  Future<Result<UserProfile>> pushProfile(UserProfile profile) async {
    return withRetryResult(() async {
      try {
        final client = _client;
        if (client == null) {
          return Failure(
            app_error.AuthException(
              message: 'Supabase not initialized',
              code: 'SUPABASE_NOT_INIT',
            ),
          );
        }

        final userIdResult = await resolveUserId(fallback: profile.userId);
        if (userIdResult.isFailure) {
          return Failure(userIdResult.exceptionOrNull()!);
        }

        final resolvedUserId = userIdResult.getOrNull()!;

        final payload = {
          'user_id': resolvedUserId,
          'display_name': profile.displayName,
          'avatar_url': profile.avatarUrl,
          'gender': profile.gender,
          'age': profile.age,
          'height_cm': profile.heightCm,
          'birth_date': profile.birthDate?.toIso8601String().split('T').first,
          'morphology': profile.morphology,
          'preferred_styles': profile.preferredStyles,
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          final data = await client
              .from('profiles')
              .upsert(payload, onConflict: 'user_id')
              .select()
              .maybeSingle();

          if (data == null) {
            return Failure(
              app_error.DatabaseException(
                message: 'Profile update returned no data',
                code: 'NO_DATA_RETURNED',
              ),
            );
          }

          final profileJson = {
            'userId': data['user_id'],
            'displayName': data['display_name'],
            'avatarUrl': data['avatar_url'],
            'gender': data['gender'],
            'age': data['age'],
            'heightCm': data['height_cm'],
            'birthDate': data['birth_date'],
            'morphology': data['morphology'],
            'preferredStyles': data['preferred_styles'] ?? <dynamic>[],
          };

          try {
            final savedProfile = UserProfile.fromJson(profileJson);
            return Success(savedProfile);
          } catch (e, st) {
            return Failure(
              app_error.ParseException(
                message: 'Failed to parse saved profile: $e',
                originalError: e,
                stackTrace: st,
              ),
            );
          }
        } on PostgrestException catch (error, st) {
          // Retro-compat: certains environnements n'ont pas la colonne height_cm
          if (error.code == '42703') {
            final fallbackPayload = Map<String, dynamic>.from(payload)
              ..remove('height_cm');

            try {
              final data = await client
                  .from('profiles')
                  .upsert(fallbackPayload, onConflict: 'user_id')
                  .select()
                  .maybeSingle();

              if (data == null) {
                return Failure(
                  app_error.DatabaseException(
                    message: 'Profile update (fallback) returned no data',
                    code: 'NO_DATA_RETURNED',
                  ),
                );
              }

              final profileJson = {
                'userId': data['user_id'],
                'displayName': data['display_name'],
                'avatarUrl': data['avatar_url'],
                'gender': data['gender'],
                'age': data['age'],
                'heightCm': data['height_cm'] ?? 170,
                'birthDate': data['birth_date'],
                'morphology': data['morphology'],
                'preferredStyles': data['preferred_styles'] ?? <dynamic>[],
              };

              try {
                final savedProfile = UserProfile.fromJson(profileJson);
                return Success(savedProfile);
              } catch (e, st) {
                return Failure(
                  app_error.ParseException(
                    message: 'Failed to parse saved profile (fallback): $e',
                    originalError: e,
                    stackTrace: st,
                  ),
                );
              }
            } on PostgrestException catch (e2, st2) {
              return Failure(
                app_error.DatabaseException(
                  message: 'Database error (fallback): ${e2.message}',
                  code: e2.code,
                  originalError: e2,
                  stackTrace: st2,
                ),
              );
            }
          }

          return Failure(
            app_error.DatabaseException(
              message: 'Database error: ${error.message}',
              code: error.code,
              constraint: error.code == '23505' ? 'unique_constraint' : null,
              originalError: error,
              stackTrace: st,
            ),
          );
        }
      } catch (e, st) {
        if (e is app_error.AppException) return Failure(e);
        return Failure(
          app_error.UnknownException(
            message: 'Unknown error pushing profile: $e',
            originalError: e,
            stackTrace: st,
          ),
        );
      }
    });
  }

  Future<Result<String?>> validateProfileSchema() async {
    try {
      final client = _client;
      if (client == null) {
        return Failure(
          app_error.AuthException(
            message: 'Supabase not initialized',
            code: 'SUPABASE_NOT_INIT',
          ),
        );
      }

      await client.from('profiles').select('user_id,height_cm').limit(1);
      return const Success(null); // null = no error
    } on PostgrestException catch (e, st) {
      if (e.code == '42703') {
        return Failure(
          app_error.DatabaseException(
            message:
                'Schéma Supabase obsolète détecté: colonne profiles.height_cm manquante. '
                'Exécutez docs/sql/supabase_full_setup.sql',
            code: e.code,
            originalError: e,
            stackTrace: st,
          ),
        );
      }
      return Failure(
        app_error.DatabaseException(
          message:
              'Verification schema Supabase indisponible (${e.code ?? 'unknown'}).',
          code: e.code,
          originalError: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Failure(
        app_error.UnknownException(
          message: 'Verification schema Supabase indisponible: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Result<String>> uploadAvatarBytes({
    required Uint8List bytes,
    required String userId,
    String fileExtension = 'jpg',
  }) async {
    return withRetryResult(() async {
      try {
        final client = _client;
        if (client == null) {
          return Failure(
            app_error.AuthException(
              message: 'Supabase not initialized',
              code: 'SUPABASE_NOT_INIT',
            ),
          );
        }

        if (userId.isEmpty) {
          return Failure(
            app_error.ValidationException(message: 'User ID cannot be empty'),
          );
        }

        if (bytes.isEmpty) {
          return Failure(
            app_error.ValidationException(message: 'Image bytes cannot be empty'),
          );
        }

        final ext = fileExtension.toLowerCase().replaceAll('.', '');
        final path =
            '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

        try {
          await client.storage
              .from(avatarBucket)
              .uploadBinary(
                path,
                bytes,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
                ),
              );

          final url = client.storage.from(avatarBucket).getPublicUrl(path);
          return Success(url);
        } on StorageException catch (e, st) {
          return Failure(
            app_error.DatabaseException(
              message: 'Storage error: ${e.message}',
              originalError: e,
              stackTrace: st,
            ),
          );
        }
      } catch (e, st) {
        if (e is app_error.AppException) return Failure(e);
        return Failure(
          app_error.UnknownException(
            message: 'Unknown error uploading avatar: $e',
            originalError: e,
            stackTrace: st,
          ),
        );
      }
    });
  }
}
