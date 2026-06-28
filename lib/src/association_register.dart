class RegisteredAssociation {
  final String name;
  final String sourceCollection;
  final String targetCollection;
  final int sourceId;
  final int targetId;

  RegisteredAssociation({
    required this.name,
    required this.sourceCollection,
    required this.targetCollection,
    required this.sourceId,
    required this.targetId,
  });
}

class AssociationRegistry {
  static final Map<String, List<int>> _targetToSourceIds = {};
  static final AssociationRegistry _instance = AssociationRegistry._internal();

  AssociationRegistry._internal();

  factory AssociationRegistry() {
    return _instance;
  }

  String buildTargetKey({
    required String sourceCollection,
    required String targetCollection,
    required int targetId,
  }) {
    return '$sourceCollection:$targetCollection:$targetId';
  }

  void register(RegisteredAssociation association) {
    final targetKey = buildTargetKey(
      sourceCollection: association.sourceCollection,
      targetCollection: association.targetCollection,
      targetId: association.targetId,
    );
    if (_targetToSourceIds[targetKey] == null) {
      _targetToSourceIds[targetKey] = [];
    }
    _targetToSourceIds[targetKey]!.add(association.sourceId);
  }

  void registerAssociation({
    required String name,
    required String sourceCollection,
    required String targetCollection,
    required int sourceId,
    required int targetId,
  }) {
    final association = RegisteredAssociation(
      name: name,
      sourceCollection: sourceCollection,
      targetCollection: targetCollection,
      sourceId: sourceId,
      targetId: targetId,
    );
    register(association);
  }

  List<int> getInverseIds({
    required String sourceCollection,
    required String targetCollection,
    required int sourceId,
  }) {
    final targetKey = buildTargetKey(
      sourceCollection: targetCollection,
      targetCollection: sourceCollection,
      targetId: sourceId,
    );
    return _targetToSourceIds[targetKey] ?? [];
  }

  void clear() {
    _targetToSourceIds.clear();
  }
}
