import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:magicmirror/core/utils/app_logger.dart';

/// Service de cache d'images d'avatar par utilisateur avec synchronisation cloud
class UserAvatarCacheService {
  static Future<Directory> _getAvatarDir() async {
    final tempDir = await getTemporaryDirectory();
    final avatarDir = Directory('${tempDir.path}/user_avatars');
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }
    return avatarDir;
  }

  static Future<File> getCachedAvatarFile(String userId) async {
    final dir = await _getAvatarDir();
    final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${dir.path}/avatar_$safeUserId.jpg');
  }

  /// Charge le fichier local s'il existe, sinon télécharge depuis le cloud Supabase
  static Future<File?> syncAndGetAvatarFile(
    String userId,
    String avatarUrl,
  ) async {
    if (userId.isEmpty || avatarUrl.isEmpty) return null;
    if (!avatarUrl.startsWith('http://') && !avatarUrl.startsWith('https://')) {
      return null;
    }

    try {
      final file = await getCachedAvatarFile(userId);

      if (!await file.exists()) {
        final response = await http.get(Uri.parse(avatarUrl));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await file.writeAsBytes(response.bodyBytes, flush: true);
          logger.info(
            'Avatar téléchargé et mis en cache pour $userId',
            tag: 'AvatarCache',
          );
        }
      } else {
        // Rafraîchissement silencieux en arrière-plan
        _downloadInBackground(userId, avatarUrl, file);
      }

      return await file.exists() ? file : null;
    } catch (e) {
      logger.warning('Erreur sync avatar cache: $e', tag: 'AvatarCache');
      return null;
    }
  }

  static void _downloadInBackground(
    String userId,
    String avatarUrl,
    File localFile,
  ) {
    http.get(Uri.parse(avatarUrl)).then((response) async {
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await localFile.writeAsBytes(response.bodyBytes, flush: true);
      }
    }).catchError((_) {});
  }

  /// Sauvegarde les octets d'un avatar uploadé localement
  static Future<File?> saveAvatarBytes(String userId, Uint8List bytes) async {
    try {
      final file = await getCachedAvatarFile(userId);
      await file.writeAsBytes(bytes, flush: true);
      logger.info(
        'Avatar sauvegardé localement pour $userId',
        tag: 'AvatarCache',
      );
      return file;
    } catch (e) {
      logger.error('Erreur sauvegarde bytes avatar: $e', tag: 'AvatarCache');
      return null;
    }
  }

  /// Supprime tous les avatars en cache (déconnexion / purge de compte)
  static Future<void> clearAllCachedAvatars() async {
    try {
      final dir = await _getAvatarDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        logger.info(
          'Tous les avatars en cache ont été supprimés',
          tag: 'AvatarCache',
        );
      }
    } catch (e) {
      logger.error('Erreur nettoyage avatars cache: $e', tag: 'AvatarCache');
    }
  }
}
