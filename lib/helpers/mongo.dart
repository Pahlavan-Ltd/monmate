import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongo_mate/helpers/toast.dart';

class MongoHelper {
  static final MongoHelper _mongoService = MongoHelper._internal();
  Db? _database;
  String _lastConnectedUri = '';

  factory MongoHelper() {
    return _mongoService;
  }

  MongoHelper._internal();

  Future<bool> connect(String uri) async {
    try {
      if (_database != null && _database!.isConnected) {
        if (_lastConnectedUri == uri) {
          return true;
        }
        await _database!.close();
      }
      _database = await Db.create(uri);
      await _database!.open();
      _lastConnectedUri = uri;
      return true;
    } catch (error) {
      ToastHelper.show(error.toString());
      _lastConnectedUri = '';
      return false;
    }
  }

  Future<void> reconnect() async {
    try {
      if ((_database == null || !(_database!.isConnected)) &&
          _lastConnectedUri.isNotEmpty) {
        await connect(_lastConnectedUri);
      }
    } catch (error) {
      ToastHelper.show("Reconnecting Failed: $error");
    }
  }

  Future<List<String>> getCollectionNames() async {
    try {
      await reconnect();
      var list = (await _database!.getCollectionNames())
          .where((element) => element != null)
          .map((e) => e as String)
          .toList();
      list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return list;
    } catch (error) {
      ToastHelper.show(error.toString());
      return Future<List<String>>.value(<String>[]);
    }
  }

  Future<int> getRecordCount(String collection) async {
    try {
      await reconnect();
      return await _database!.collection(collection).count();
    } catch (e) {
      return -1;
    }
  }

  Future<void> createCollection(String name) async {
    try {
      await reconnect();
      var result = await _database!.createCollection(name);
      if (result.keys.any((element) => element == 'errmsg')) {
        throw result['errmsg'].toString();
      }
    } catch (error) {
      ToastHelper.show(error.toString());
    }
  }

  Future<bool> deleteCollection(String name) async {
    try {
      await reconnect();
      return await _database!.dropCollection(name);
    } catch (error) {
      ToastHelper.show(error.toString());
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> find(
      String collection,
      int page,
      int pageSize,
      Map<String, dynamic>? filter,
      Map<String, Object>? sort) async {
    try {
      if (page < 0) {
        page = 0;
      }
      if (pageSize <= 0) {
        pageSize = 1;
      }
      await reconnect();
      return await _database!
          .collection(collection)
          .modernFind(filter: filter, sort: sort)
          .skip(page)
          .take(pageSize)
          .toList();
    } catch (error) {
      ToastHelper.show(error.toString());
      return Future<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
    }
  }

  Future<bool> deleteRecord(String collection, dynamic id) async {
    try {
      await reconnect();
      var result =
          await _database!.collection(collection).deleteOne({'_id': id});
      return result.isSuccess;
    } catch (error) {
      ToastHelper.show(error.toString());
      return false;
    }
  }

  Future<bool> insertRecord(String collection, dynamic data) async {
    try {
      await reconnect();
      await _database!.collection(collection).insert(data);
      return true;
    } catch (error) {
      ToastHelper.show(error.toString());
      return false;
    }
  }

  Future<bool> updateRecord(String collection, dynamic id, dynamic data) async {
    try {
      await reconnect();
      var result =
          await _database!.collection(collection).replaceOne({'_id': id}, data);
      if (result.hasWriteErrors) {
        throw result.writeError!.errmsg!.toString();
      }
      return true;
    } catch (error) {
      ToastHelper.show(error.toString());
      return false;
    }
  }
}
