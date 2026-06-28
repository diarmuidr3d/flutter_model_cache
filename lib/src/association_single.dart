import 'association_register.dart';
import 'model.dart';
import 'model_factory.dart';

class SingleAssociation<T extends Model> {
  SingleAssociation({
    required this.sourceCollection,
    required this.sourceId,
    required this.targetCollection,
    required this.name,
    this.id,
  }) {
    if (id != null && sourceId != null) {
      AssociationRegistry().registerAssociation(
        name: name,
        sourceCollection: sourceCollection,
        targetCollection: targetCollection,
        sourceId: sourceId!,
        targetId: id!,
      );
    }
  }

  factory SingleAssociation.fromModel({
    required String sourceCollection,
    required int? sourceId,
    required T model,
    required String name,
  }) {
    return SingleAssociation(
      sourceCollection: sourceCollection,
      targetCollection: model.collectionName,
      id: model.id,
      sourceId: sourceId,
      name: name,
    );
  }

  factory SingleAssociation.fromJson({
    required String sourceCollectionName,
    required int? sourceId,
    required String targetCollectionName,
    required String name,
    required Map<String, Object?> json,
  }) {
    var model = ModelFactory().fromJson<T>(
      collectionName: targetCollectionName,
      json: json,
    );
    if (model == null) throw Exception('Model not found');
    return SingleAssociation<T>(
      sourceCollection: sourceCollectionName,
      targetCollection: targetCollectionName,
      id: model.id,
      sourceId: sourceId,
      name: name,
    );
  }

  int? id;
  String targetCollection;
  String sourceCollection;
  int? sourceId;
  String name;

  T? get peek {
    if (id == null) return null;
    return ModelFactory().peekModel<T>(id: id!, collection: targetCollection);
  }

  Future<T?> get find async {
    if (id == null) return null;
    return ModelFactory().findModel<T>(targetCollection, id!);
  }

  Future<T?> get peekOrFind async {
    return peek ?? find;
  }

  Stream<T?> get stream {
    return ModelFactory().streamModel<T>(targetCollection, id!);
  }

  Stream<T?> get findAndStream {
    return ModelFactory().findAndStreamModel<T>(targetCollection, id!);
  }

  void setValue(T model) {
    id = model.id;
    targetCollection = model.collectionName;
  }
}
