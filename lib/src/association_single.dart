import 'model.dart';
import 'model_factory.dart';

class SingleAssociation<T extends Model> {
  SingleAssociation({required this.collection, this.id});

  factory SingleAssociation.fromModel(T model) {
    return SingleAssociation(collection: model.collectionName, id: model.id);
  }

  factory SingleAssociation.fromJson(
    String collectionName,
    Map<String, Object?> json,
  ) {
    var model = ModelFactory().fromJson<T>(
      collectionName: collectionName,
      json: json,
    );
    if (model == null) throw Exception('Model not found');
    return SingleAssociation<T>(collection: collectionName, id: model.id);
  }

  int? id;
  String collection;

  T? get peek {
    if (id == null) return null;
    return ModelFactory().peekModel<T>(id: id!, collection: collection);
  }

  Future<T?> get find async {
    if (id == null) return null;
    return ModelFactory().findModel<T>(collection, id!);
  }

  Future<T?> get peekOrFind async {
    return peek ?? find;
  }

  Stream<T?> get stream {
    return ModelFactory().streamModel<T>(collection, id!);
  }

  Stream<T?> get findAndStream {
    return ModelFactory().findAndStreamModel<T>(collection, id!);
  }

  void setValue(T model) {
    id = model.id;
    collection = model.collectionName;
  }
}
