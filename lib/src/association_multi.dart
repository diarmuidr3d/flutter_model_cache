import 'model.dart';
import 'model_factory.dart';

class MultiAssociation<T extends Model> {
  MultiAssociation({required this.collection, this.ids});

  factory MultiAssociation.fromModels(List<T> models) {
    return MultiAssociation(
        collection: models.first.collectionName,
        ids: models.map((e) => e.id!).toList());
  }

  factory MultiAssociation.fromJson(String collectionName, List<dynamic> json) {
    List<int> ids = [];
    for (var element in json) {
      var model = ModelFactory()
          .fromJson<T>(collectionName: collectionName, json: element);
      if (model == null) throw Exception('Model not found');
      ids.add(model.id!);
    }
    return MultiAssociation<T>(
      collection: collectionName,
      ids: ids,
    );
  }

  List<int>? ids;
  String collection;

  List<T?> get peek {
    if (ids == null) return [];
    List<T?> models = [];
    for (var id in ids!) {
      models.add(ModelFactory().peekModel<T>(id: id, collection: collection));
    }
    return models;
  }

  List<Future<T?>> get find {
    if (ids == null || ids!.isEmpty) return [];
    return ids!
        .map((id) => ModelFactory().findModel<T>(collection, id))
        .toList();
  }

  int get length => ids?.length ?? 0;

  bool get isEmpty => ids == null || ids!.isEmpty;

  bool get isNotEmpty => !isEmpty;

  MultiAssociation add(T model) {
    ids ??= [];
    ids!.add(model.id!);
    return this;
  }

  MultiAssociation setValue(List<T> models) {
    if (models.isEmpty) {
      ids = [];
      return this;
    }
    ids = models.map((e) => e.id!).toList();
    collection = models.first.collectionName;
    return this;
  }
}
