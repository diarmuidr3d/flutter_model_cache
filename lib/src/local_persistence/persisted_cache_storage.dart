import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PersistedCacheStorage {
  static PersistedCacheStorage _singleton = PersistedCacheStorage._internal();

  var _storage = const FlutterSecureStorage();

  factory PersistedCacheStorage() {
    return _singleton;
  }

  PersistedCacheStorage._internal();

  void setMockStoreForTest(FlutterSecureStorage store) {
    _storage = store;
  }

  Future<String?> read({required String collection, int? id}) async {
    if (id != null) {
      _storage.read(
        key: _key(collection: collection, id: id),
      );
    }
    return _storage.read(key: collection);
  }

  Future<void> write({
    required String collection,
    int? id,
    required String value,
  }) async {
    return _storage.write(
      key: _key(collection: collection, id: id),
      value: value,
    );
  }

  Future<void> delete({required String collection, int? id}) async {
    return _storage.delete(
      key: _key(collection: collection, id: id),
    );
  }

  String _key({required String collection, int? id}) {
    return id != null ? '$collection/$id' : collection;
  }

  PersistedCacheStorage replaceForTesting(PersistedCacheStorage storage) {
    _singleton = storage;
    return _singleton;
  }
}
