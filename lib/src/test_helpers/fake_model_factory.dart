import 'dart:async';

import 'package:flutter_model_cache/flutter_model_cache.dart';
import 'package:flutter_model_cache/src/local_persistence/fake_persisted_cache_storage.dart';
import 'package:flutter_model_cache/src/local_persistence/persisted_cache_storage.dart';
import 'package:flutter_model_cache/src/test_helpers/id_generator.dart';

class FakeModelFactory extends GenericModelFactory implements ModelFactory {
  static final FakeModelFactory _modelFactory = FakeModelFactory._new();

  StreamController<Model?>? testStreamController;
  bool useTestController = false;
  Type? _testControllerType;

  FakeModelFactory._new();

  int findCalledCount = 0;
  int saveCalledCount = 0;

  factory FakeModelFactory() {
    ModelFactory().replaceForTesting(_modelFactory);
    PersistedCacheStorage().setMockStoreForTest(FakeFlutterSecureStorage());
    return _modelFactory;
  }

  void clear() {
    modelCache.clear();
    findCalledCount = 0;
    saveCalledCount = 0;
    useTestController = false;
    testStreamController?.close();
    testStreamController = null;
    _testControllerType = null;
  }

  void setTestController<T extends Model?>() {
    testStreamController?.close();
    testStreamController = StreamController<T>.broadcast();
    _testControllerType = T;
    useTestController = true;
  }

  @override
  Stream<T?> streamModel<T extends Model>(String collectionName, int id) {
    if (useTestController &&
        testStreamController != null &&
        T == _testControllerType) {
      return testStreamController!.stream.cast<T?>();
    }
    return super.streamModel<T>(collectionName, id);
  }

  @override
  Future<T?> findModel<T extends Model>(String collectionName, int id) async {
    return peekModel<T>(collection: collectionName, id: id);
  }

  @override
  Future<List<T>> findModels<T extends Model>(String collectionName) async {
    var models = modelCache[collectionName];
    if (models == null) return <T>[];
    List<T> items = [];
    models.forEach((value) {
      items.add(value as T);
    });
    modelCache[collectionName]?.loaded = true;
    return items;
  }

  @override
  Future<T> saveModel<T extends Model>(T model) {
    saveCalledCount++;
    model.id ??= IdGenerator().newId();
    model = add<T>(model);
    return Future.value(model);
  }

  @override
  ModelFactory replaceForTesting(ModelFactory modelFactory) {
    return this;
  }

  @override
  Future<T?> deleteModel<T extends Model>(T model) async {
    model.deleted = true;
    remove<T>(model);
    return model;
  }

  @override
  Future<List<T>> queryModels<T extends Model>(
    String collectionName, {
    Map<String, dynamic>? queryParams,
  }) {
    return findModels(collectionName);
  }

  @override
  Future<T?> deleteById<T extends Model>(String collectionName, int id) {
    return Future.value(removeById<T>(collectionName, id));
  }
}
