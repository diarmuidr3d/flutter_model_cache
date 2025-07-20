import 'dart:async';
import 'dart:convert';

import 'package:flutter_model_cache/src/stream_state.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'generic_model_factory.dart';
import 'model.dart';

class ModelFactory extends GenericModelFactory {
  static const appUrl = 'app.feirmapp.ie';

  static ModelFactory _modelFactory = ModelFactory._internal();

  ModelFactory._internal();

  factory ModelFactory() {
    return _modelFactory;
  }

  @override
  Future<List<T>> findModels<T extends Model>(String collectionName) async {
    updateStreamController<T>(
      collectionName,
      streamState: StreamStates.loading,
    );
    List<T> items = await queryModels<T>(collectionName);
    replaceCacheForCollection<T>(collectionName, items);
    return items;
  }

  @override
  Future<T?> findModel<T extends Model>(String collectionName, int id) async {
    var url = _urlForModel(collectionName, id);
    var response = await httpClient.get(url);
    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      T? model = fromJson<T>(collectionName: collectionName, json: body);
      return model;
    } else {
      throw Exception('Failed to load $collectionName with id $id');
    }
  }

  @override
  Future<T?> saveModel<T extends Model>(T model) async {
    try {
      if (!model.isPersisted) {
        return _createModel<T>(model);
      }
      var id = model.id;
      var collectionName = model.collectionName;
      var url = Uri.https('app.feirmapp.ie', '$collectionName/$id');
      var response = await httpClient.put(url, body: model.toJson());
      return _handleSingleModelResponse(
        collectionName: collectionName,
        response: response,
      );
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print(e);
        print(stacktrace);
      }
      throw Exception('Failed to save ${model.collectionName}');
    }
  }

  @override
  Future<T?> deleteModel<T extends Model>(T model) async {
    if (!model.isPersisted) {
      return null;
    }
    var id = model.id;
    var collectionName = model.collectionName;
    deleteById<T>(collectionName, id!);
    model.deleted = true;
    return model;
  }

  Future<T?> deleteById<T extends Model>(String collectionName, int id) async {
    try {
      var url = Uri.https('app.feirmapp.ie', '$collectionName/$id');
      var response = await httpClient.delete(url);
      T? model;
      if (response.statusCode == 200) {
        model = removeById<T>(collectionName, id);
        model?.deleted = true;
      } else {
        throw Exception();
      }
      return model;
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print(e);
        print(stacktrace);
      }
      throw Exception('Failed to delete $collectionName');
    }
  }

  @override
  Future<List<T>> queryModels<T extends Model>(
    String collectionName, {
    Map<String, dynamic>? queryParams,
  }) async {
    var url = _urlForCollection(collectionName, queryParams: queryParams);
    try {
      final paramsToAdd = url.queryParameters;
      if (queryParams != null) {
        queryParams.forEach((key, value) {
          paramsToAdd[key] = value.toString();
        });
      }
      url = url.replace(queryParameters: paramsToAdd);
      var response = await httpClient.get(url);
      if (response.statusCode == 200) {
        var body = json.decode(response.body);
        List<T> items = [];
        body.forEach(
          (data) => items.add(
            fromJson<T>(collectionName: collectionName, json: Map.from(data))!,
          ),
        );
        return items;
      } else {
        throw Exception('Failed to load $collectionName');
      }
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print(e);
        print(stacktrace);
      }
      return [];
    }
  }

  Future<T?> _createModel<T extends Model>(T model) async {
    var collectionName = model.collectionName;
    var url = Uri.https('app.feirmapp.ie', collectionName);
    var response = await httpClient.post(url, body: model.toJson());
    return _handleSingleModelResponse<T>(
      collectionName: collectionName,
      response: response,
    );
  }

  Uri _urlForCollection(
    String collectionName, {
    Map<String, dynamic>? queryParams,
  }) {
    if (queryParams != null) {
      return Uri.https(appUrl, collectionName, queryParams);
    }
    return Uri.https(appUrl, collectionName);
  }

  Uri _urlForModel(String collectionName, int? id) {
    return Uri.https(appUrl, '$collectionName/$id');
  }

  T? _handleSingleModelResponse<T extends Model>({
    required String collectionName,
    required http.Response response,
  }) {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return fromJson<T>(
        collectionName: collectionName,
        json: json.decode(response.body),
      );
    } else {
      throw Exception('Failed to load $collectionName');
    }
  }

  ModelFactory replaceForTesting(ModelFactory modelFactory) {
    _modelFactory = modelFactory;
    return _modelFactory;
  }
}
