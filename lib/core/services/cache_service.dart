import 'dart:async';
import 'package:magicmirror/core/utils/app_logger.dart';

/// Service de cache generic avec support TTL (Time-To-Live)
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({required this.value, required this.ttl})
    : createdAt = DateTime.now();

  /// V\u00e9rifie si le cache a expir\u00e9
  bool get isExpired {
    final expiresAt = createdAt.add(ttl);
    return DateTime.now().isAfter(expiresAt);
  }

  /// Retourne le temps restant avant expiration
  Duration get timeRemaining {
    final expiresAt = createdAt.add(ttl);
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

/// Service de cache thread-safe avec TTL automatique
class CacheService {
  static final CacheService _instance = CacheService._internal();
  final Map<String, CacheEntry> _cache = {};
  final Map<String, Timer?> _timers = {};

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  /// Ajoute une entr\u00e9e au cache avec TTL
  void set<T>(String key, T value, {Duration ttl = const Duration(hours: 1)}) {
    logger.debug(
      'Cache SET: $key (TTL: ${ttl.inSeconds}s)',
      tag: 'CacheService',
    );

    // Annuler le timer pr\u00e9c\u00e9dent si existe
    _timers[key]?.cancel();

    // Ajouter au cache
    _cache[key] = CacheEntry(value: value, ttl: ttl);

    // Cr\u00e9er un timer pour exp\u00e9dition automatique
    _timers[key] = Timer(ttl, () {
      _cache.remove(key);
      _timers.remove(key);
      logger.debug('Cache EXPIRED: $key', tag: 'CacheService');
    });
  }

  /// Retourne une valeur du cache si elle existe et n'a pas expir\u00e9
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      logger.debug('Cache MISS: $key', tag: 'CacheService');
      return null;
    }

    if (entry is! CacheEntry<T>) {
      logger.warning(
        'Cache TYPE MISMATCH: $key expected ${T.toString()}, got ${entry.runtimeType}',
        tag: 'CacheService',
      );
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _timers[key]?.cancel();
      _timers.remove(key);
      logger.debug('Cache EXPIRED (on access): $key', tag: 'CacheService');
      return null;
    }

    logger.debug(
      'Cache HIT: $key (${entry.timeRemaining.inSeconds}s left)',
      tag: 'CacheService',
    );
    return entry.value;
  }

  /// Invalide une entr\u00e9e sp\u00e9cifique
  void invalidate(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
    logger.debug('Cache INVALIDATED: $key', tag: 'CacheService');
  }

  /// Invalide toutes les entr\u00e9es avec un pr\u00e9fixe
  void invalidatePattern(String prefix) {
    final keysToRemove = _cache.keys
        .where((k) => k.startsWith(prefix))
        .toList();
    for (final key in keysToRemove) {
      invalidate(key);
    }
    logger.debug(
      'Cache INVALIDATED ($keysToRemove.length entries matching $prefix)',
      tag: 'CacheService',
    );
  }

  /// Vide tout le cache
  void clear() {
    logger.debug(
      'Cache CLEARED (${_cache.length} entries)',
      tag: 'CacheService',
    );
    for (final timer in _timers.values) {
      timer?.cancel();
    }
    _cache.clear();
    _timers.clear();
  }

  /// Retourne les stats du cache
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'keys': _cache.keys.toList(),
      'timings': _cache.map(
        (k, v) => MapEntry(k, '${v.timeRemaining.inSeconds}s remaining'),
      ),
    };
  }
}

// Singleton global
final cacheService = CacheService();
