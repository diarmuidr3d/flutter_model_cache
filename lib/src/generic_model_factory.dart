import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'local_persistence/persisted_cache_model.dart';
import 'local_persistence/persisted_cache_storage.dart';
import 'model.dart';
import 'model_class_cache.dart';
import 'model_list_stream.dart';
import 'stream_state.dart';

typedef ModelFromJson<T extends Model> = T Function(Map<String, Object?> json);

abstract class GenericModelFactory {
  final Map<String, ModelClassCache> modelCache = {};
  late final http.BaseClient httpClient;
  final Map<String, ModelFromJson> collectionClassMap = {};

  Future<List<T>> findModels<T extends Model>(String collectionName);

  Future<List<T>> queryModels<T extends Model>(
    String collectionName, {
    Map<String, dynamic>? queryParams,
  });

  Stream<ModelListStream<T>> findAndModelListStreamModels<T extends Model>(
    String collectionName,
  ) {
    findModels<T>(collectionName);
    return modelListStreamModels<T>(collectionName);
  }

  Stream<List<T>> findAndStreamModels<T extends Model>(String collectionName) {
    findModels<T>(collectionName);
    return streamModels<T>(collectionName);
  }

  Future<T?> findModel<T extends Model>(String collectionName, int id);

  Stream<T?> findAndStreamModel<T extends Model>(
    String collectionName,
    int id,
  ) {
    if (isPersistedCacheModel<T>()) findInPersistedStore<T>(collectionName, id);
    findModel<T>(collectionName, id);
    return streamModel<T>(collectionName, id);
  }

  Future<T?> saveModel<T extends Model>(T model);

  Future<T?> deleteModel<T extends Model>(T model);

  List<T> peekModels<T extends Model>({required String collection}) {
    final values = modelCache[collection]?.peekAll() as List<T>?;
    return values ?? [];
  }

  T? peekModel<T extends Model>({required String collection, required int id}) {
    return modelCache[collection]?[id] as T?;
  }

  Future<T?> findInPersistedStore<T extends Model>(
    String collectionName,
    int id,
  ) async {
    String? data = await PersistedCacheStorage().read(
      collection: collectionName,
      id: id,
    );
    if (data != null) {
      var body = json.decode(data);
      T? model = fromJson<T>(collectionName: collectionName, json: body);
      return model;
    }
    return null;
  }

  Stream<ModelListStream<T>> modelListStreamModels<T extends Model>(
    String collectionName,
  ) {
    return _getModelListStreamController<T>(collectionName).stream;
  }

  Stream<List<T>> streamModels<T extends Model>(String collectionName) {
    return _getStreamController<T>(collectionName).stream;
  }

  Stream<T?> streamModel<T extends Model>(String collectionName, int id) {
    return _getStreamControllerForId<T>(collectionName, id: id).stream;
  }

  StreamController<ModelListStream<T>>
  _getModelListStreamController<T extends Model>(String collectionName) {
    ensureCacheExists<T>(collectionName);
    final controller = modelCache[collectionName]!.modelListStreamController();
    return controller as StreamController<ModelListStream<T>>;
  }

  StreamController<List<T>> _getStreamController<T extends Model>(
    String collectionName,
  ) {
    ensureCacheExists<T>(collectionName);
    final controller = modelCache[collectionName]!.streamController();
    return controller as StreamController<List<T>>;
  }

  StreamController<T?> _getStreamControllerForId<T extends Model>(
    String collectionName, {
    required int id,
  }) {
    ensureCacheExists<T>(collectionName);
    return modelCache[collectionName]!.streamControllerForId(id)
        as StreamController<T?>;
  }

  void updateStreamController<T extends Model>(
    String collectionName, {
    StreamState streamState = StreamStates.loaded,
  }) {
    modelCache[collectionName]?.updateStreamController(
      streamState: streamState,
    );
  }

  void ensureCacheExists<T extends Model>(String collectionName) {
    if (modelCache[collectionName] == null) {
      modelCache[collectionName] = ModelClassCache<T>(collectionName);
    }
  }

  T add<T extends Model>(T model) {
    ensureCacheExists<T>(model.collectionName);
    modelCache[model.collectionName]!.add(model);
    PersistedCacheStorage().write(
      collection: model.collectionName,
      id: model.id,
      value: json.encode(model.toJson()),
    );
    return model;
  }

  T remove<T extends Model>(T model) {
    removeById<T>(model.collectionName, model.id!);
    return model;
  }

  T? removeById<T extends Model>(String collectionName, int id) {
    final model = (modelCache[collectionName] as ModelClassCache<T>?)
        ?.removeById(id);
    PersistedCacheStorage().delete(collection: collectionName, id: id);
    return model;
  }

  T? fromJson<T extends Model>({
    required String collectionName,
    required Map<String, Object?> json,
  }) {
    T? model = modelFromJson<T>(collectionName: collectionName, json: json);
    if (model == null) return model;
    return add<T>(model);
  }

  T? modelFromJson<T extends Model>({
    required String collectionName,
    required Map<String, Object?> json,
  }) {
    final fromJson = collectionClassMap[collectionName];
    if (fromJson == null) {
      throw UnimplementedError('No model for $collectionName');
    }
    return fromJson(json) as T;
  }

  void clearForCollection<T extends Model>(String collectionName) {
    modelCache.remove(collectionName);
  }

  void replaceCacheForCollection<T extends Model>(
    String collectionName,
    List<T> models,
  ) {
    ensureCacheExists<T>(collectionName);
    modelCache[collectionName]!.replaceAll(models);
  }

  bool areModelsLoaded(String collectionName) {
    return modelCache[collectionName] != null;
  }

  bool isPersistedCacheModel<T extends Model>() {
    return T is PersistedCacheModel;
  }

  void registerHttpClient(http.BaseClient httpClient) {
    this.httpClient = httpClient;
  }

  void registerModelClass<T extends Model>(
    String collectionName,
    ModelFromJson<T> fromJson,
  ) {
    collectionClassMap[collectionName] = fromJson;
  }
}
