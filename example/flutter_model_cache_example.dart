import 'package:flutter_model_cache/flutter_model_cache.dart';

class Animal extends Model {
  final String name;
  Animal({required this.name});

  static const String classCollectionName = 'animals';
  @override
  String get collectionName => classCollectionName;

  factory Animal.fromJson(Map<String, Object?> json) {
    return Animal(name: json['name'] as String);
  }
}

void main() async {
  final modelFactory = ModelFactory();
  modelFactory.registerModelClass(
    Animal.classCollectionName,
    (json) => Animal.fromJson(json),
  );
  final animal = await modelFactory.findModel(Animal.classCollectionName, 1);
  print(animal);
}
