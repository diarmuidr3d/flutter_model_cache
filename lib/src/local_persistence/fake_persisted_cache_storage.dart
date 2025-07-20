import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String?> _store = {};

  @override
  Future<String?> read(
      {AndroidOptions? aOptions,
      IOSOptions? iOptions,
      required String key,
      LinuxOptions? lOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions,
      WebOptions? webOptions}) {
    return Future.value(_store[key]);
  }

  @override
  Future<void> write(
      {AndroidOptions? aOptions,
      IOSOptions? iOptions,
      required String key,
      LinuxOptions? lOptions,
      MacOsOptions? mOptions,
      required String? value,
      WindowsOptions? wOptions,
      WebOptions? webOptions}) {
    _store[key] = value;
    return Future.value();
  }

  @override
  Future<void> delete(
      {AndroidOptions? aOptions,
      IOSOptions? iOptions,
      required String key,
      LinuxOptions? lOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions,
      WebOptions? webOptions}) {
    _store.remove(key);
    return Future.value();
  }
}
