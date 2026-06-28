import '../flutter_model_cache.dart';

class InverseAssociation<T extends Model> {
  InverseAssociation({
    required this.sourceCollection,
    required this.sourceId,
    required this.targetCollection,
    required this.inverseName,
  });

  String sourceCollection;
  int sourceId;
  String targetCollection;
  String inverseName;

  List<T> get peek {
    final sourceIds = AssociationRegistry().getInverseIds(
      sourceCollection: sourceCollection,
      targetCollection: targetCollection,
      sourceId: sourceId,
    );
    if (sourceIds.isEmpty) return [];

    return sourceIds
        .map(
          (id) =>
              ModelFactory().peekModel<T>(id: id, collection: targetCollection),
        )
        .nonNulls
        .toList();
  }
}
