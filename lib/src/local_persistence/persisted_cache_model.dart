import 'dart:async';

import 'package:flutter_model_cache/src/model_factory.dart';

import '../model.dart';

abstract class PersistedCacheModel extends Model {
  PersistedCacheModel({super.id, super.lastUpdated});

  static const bool isCached = true;

  @override
  Future<T> save<T extends Model>() async {
    final model = await ModelFactory().saveModel<T>(this as T);
    if (model == null) throw Exception('Model not found');
    id = model.id;
    lastUpdated = model.lastUpdated;
    return model;
  }
}
