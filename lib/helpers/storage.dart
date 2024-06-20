import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageHelper {
  static final StorageHelper _storageHelper = StorageHelper._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  factory StorageHelper() {
    return _storageHelper;
  }

  StorageHelper._internal();

  Future<void> write(String key, String value) async {
    return await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
}
