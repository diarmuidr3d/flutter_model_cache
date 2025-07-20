import 'dart:async';

import 'package:flutter_model_cache/src/model_factory.dart';

abstract class Model {
  Model({this.id, DateTime? lastUpdated}) {
    this.lastUpdated = lastUpdated ?? DateTime.now();
  }

  int? id;
  late DateTime lastUpdated;
  bool deleted = false;

  String get collectionName;

  String get recordPath => '$collectionName/$id';

  Map<String, Object?> toJson() {
    return {'id': id};
  }

  void setFieldsFromJson({
    required int id,
    required Map<String, Object?> json,
  }) {
    id = id;
    lastUpdated = DateTime.parse(json['lastUpdated'] as String);
  }

  Future<T?> delete<T extends Model>() async {
    return await ModelFactory().deleteModel<T>(this as T);
  }

  bool get isPersisted => id != null;

  Future<T> save<T extends Model>() async {
    final model = await ModelFactory().saveModel<T>(this as T);
    id = model!.id;
    lastUpdated = model.lastUpdated;
    return model;
  }

  Future<T> reload<T extends Model>() async {
    final model = await ModelFactory().findModel<T>(collectionName, id!);
    if (model == null) throw Exception('Model Not Found');
    id = model.id;
    lastUpdated = model.lastUpdated;
    return model;
  }

  void setLastUpdated() {
    lastUpdated = DateTime.now();
  }

  static DateTime? dateTimeFromJsonOrNull(Object? object) {
    if (object == null) return null;
    if (object is DateTime) {
      return object;
    }
    if (object is String) {
      return DateTime.parse(object);
    }
    return null;
  }

  @override
  operator ==(Object other) {
    if (other is! Model) return false;
    if (other.runtimeType == runtimeType) {
      if (id == null) return super == other;
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    if (id != null) return Object.hash(id, runtimeType);
    return super.hashCode;
  }
}
