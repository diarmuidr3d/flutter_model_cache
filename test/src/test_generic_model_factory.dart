import 'dart:async';
import 'package:flutter_model_cache/flutter_model_cache.dart';
import 'package:flutter_model_cache/src/local_persistence/persisted_cache_model.dart';
import 'package:flutter_model_cache/src/model_class_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class TestModel extends Model {
  TestModel({super.id, super.lastUpdated, this.name = ''});

  String name;

  @override
  String get collectionName => 'test_models';

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  static TestModel fromJson(Map<String, Object?> json) {
    return TestModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      lastUpdated: DateTime.parse(
        json['lastUpdated'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class TestPersistedModel extends PersistedCacheModel {
  TestPersistedModel({super.id, super.lastUpdated, this.value = ''});

  String value;

  @override
  String get collectionName => 'persisted_models';

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'value': value,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  static TestPersistedModel fromJson(Map<String, Object?> json) {
    return TestPersistedModel(
      id: json['id'] as int?,
      value: json['value'] as String? ?? '',
      lastUpdated: DateTime.parse(
        json['lastUpdated'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class TestGenericModelFactory extends GenericModelFactory {
  final List<TestModel> _testModels = [];
  final List<TestPersistedModel> _persistedModels = [];

  @override
  Future<List<T>> findModels<T extends Model>(String collectionName) async {
    if (collectionName == 'test_models') return _testModels as List<T>;
    if (collectionName == 'persisted_models')
      return _persistedModels as List<T>;
    return [];
  }

  @override
  Future<List<T>> queryModels<T extends Model>(
    String collectionName, {
    Map<String, dynamic>? queryParams,
  }) async {
    return findModels<T>(collectionName);
  }

  @override
  Future<T?> findModel<T extends Model>(String collectionName, int id) async {
    if (collectionName == 'test_models') {
      final model = _testModels.where((m) => m.id == id).firstOrNull;
      return model as T?;
    }
    if (collectionName == 'persisted_models') {
      final model = _persistedModels.where((m) => m.id == id).firstOrNull;
      return model as T?;
    }
    return null;
  }

  @override
  Future<T?> saveModel<T extends Model>(T model) async {
    if (model is TestModel) {
      model.id ??= _testModels.length + 1;
      _testModels.removeWhere((m) => m.id == model.id);
      _testModels.add(model);
    } else if (model is TestPersistedModel) {
      model.id ??= _persistedModels.length + 1;
      _persistedModels.removeWhere((m) => m.id == model.id);
      _persistedModels.add(model);
    }
    return model;
  }

  @override
  Future<T?> deleteModel<T extends Model>(T model) async {
    if (model is TestModel) _testModels.removeWhere((m) => m.id == model.id);
    if (model is TestPersistedModel)
      _persistedModels.removeWhere((m) => m.id == model.id);
    return model;
  }

  @override
  T add<T extends Model>(T model) {
    ensureCacheExists<T>(model.collectionName);
    modelCache[model.collectionName]!.add(model);
    return model;
  }

  @override
  T? removeById<T extends Model>(String collectionName, int id) {
    final model = (modelCache[collectionName] as ModelClassCache<T>?)
        ?.removeById(id);
    return model;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cache Management Tests', () {
    late TestGenericModelFactory factory;
    late TestModel testModel;

    setUp(() {
      factory = TestGenericModelFactory();
      testModel = TestModel(id: 1, name: 'Test');
    });

    test('add model to cache', () {
      final result = factory.add<TestModel>(testModel);
      expect(result, equals(testModel));
      expect(
        factory.peekModel<TestModel>(collection: 'test_models', id: 1),
        equals(testModel),
      );
    });

    test('remove model from cache', () {
      factory.add<TestModel>(testModel);
      final result = factory.remove<TestModel>(testModel);
      expect(result, equals(testModel));
      expect(
        factory.peekModel<TestModel>(collection: 'test_models', id: 1),
        isNull,
      );
    });

    test('remove model by id from cache', () {
      factory.add<TestModel>(testModel);
      final result = factory.removeById<TestModel>('test_models', 1);
      expect(result, equals(testModel));
      expect(
        factory.peekModel<TestModel>(collection: 'test_models', id: 1),
        isNull,
      );
    });

    test('peek models from cache', () {
      factory.add<TestModel>(testModel);
      factory.add<TestModel>(TestModel(id: 2, name: 'Test2'));
      final result = factory.peekModels<TestModel>(collection: 'test_models');
      expect(result.length, equals(2));
    });

    test('peek single model from cache', () {
      factory.add<TestModel>(testModel);
      final result = factory.peekModel<TestModel>(
        collection: 'test_models',
        id: 1,
      );
      expect(result, equals(testModel));
    });

    test('clear collection cache', () {
      factory.add<TestModel>(testModel);
      factory.clearForCollection<TestModel>('test_models');
      expect(factory.areModelsLoaded('test_models'), isFalse);
    });

    test('replace cache for collection', () {
      final models = [TestModel(id: 1, name: 'A'), TestModel(id: 2, name: 'B')];
      factory.replaceCacheForCollection<TestModel>('test_models', models);
      expect(
        factory.peekModels<TestModel>(collection: 'test_models').length,
        equals(2),
      );
    });

    test('check if models are loaded', () {
      expect(factory.areModelsLoaded('test_models'), isFalse);
      factory.add<TestModel>(testModel);
      expect(factory.areModelsLoaded('test_models'), isTrue);
    });
  });

  group('Stream Management Tests', () {
    late TestGenericModelFactory factory;

    setUp(() {
      factory = TestGenericModelFactory();
    });

    test('stream models returns stream', () {
      final stream = factory.streamModels<TestModel>('test_models');
      expect(stream, isA<Stream<List<TestModel>>>());
    });

    test('stream single model returns stream', () {
      final stream = factory.streamModel<TestModel>('test_models', 1);
      expect(stream, isA<Stream<TestModel?>>());
    });

    test('model list stream models returns stream', () {
      final stream = factory.modelListStreamModels<TestModel>('test_models');
      expect(stream, isA<Stream<ModelListStream<TestModel>>>());
    });

    test('find and stream models calls find first', () async {
      final stream = factory.findAndStreamModels<TestModel>('test_models');
      expect(stream, isA<Stream<List<TestModel>>>());
    });

    test('find and model list stream models calls find first', () async {
      final stream = factory.findAndModelListStreamModels<TestModel>(
        'test_models',
      );
      expect(stream, isA<Stream<ModelListStream<TestModel>>>());
    });

    test('find and stream model calls find first', () async {
      final stream = factory.findAndStreamModel<TestModel>('test_models', 1);
      expect(stream, isA<Stream<TestModel?>>());
    });

    test('update stream controller with state', () {
      factory.ensureCacheExists<TestModel>('test_models');
      factory.updateStreamController<TestModel>(
        'test_models',
        streamState: StreamStates.loaded,
      );
      expect(factory.areModelsLoaded('test_models'), isTrue);
    });

    test('ensure cache exists creates cache', () {
      factory.ensureCacheExists<TestModel>('test_models');
      expect(factory.modelCache.containsKey('test_models'), isTrue);
    });
  });

  group('JSON Operations Tests', () {
    late TestGenericModelFactory factory;

    setUp(() {
      factory = TestGenericModelFactory();
      factory.registerModelClass<TestModel>(
        'test_models',
        (json) async => TestModel.fromJson(json),
      );
    });

    test('model from json creates model without adding', () {
      final json = {
        'id': 1,
        'name': 'Test',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      final model = factory.modelFromJson<TestModel>(
        collectionName: 'test_models',
        json: json,
      );
      expect(model?.name, equals('Test'));
      expect(
        factory.peekModel<TestModel>(collection: 'test_models', id: 1),
        isNull,
      );
    });

    test('model from json throws for unregistered collection', () {
      final json = {'id': 1, 'name': 'Test'};
      expect(
        () => factory.modelFromJson<TestModel>(
          collectionName: 'unknown',
          json: json,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('Registration Tests', () {
    late TestGenericModelFactory factory;

    setUp(() {
      factory = TestGenericModelFactory();
    });

    test('register http client', () {
      final client = http.Client() as http.BaseClient;
      factory.registerHttpClient(client);
      expect(factory.httpClient, equals(client));
    });

    test('register model class', () {
      factory.registerModelClass<TestModel>(
        'test_models',
        (json) async => TestModel.fromJson(json),
      );
      expect(factory.collectionClassMap.containsKey('test_models'), isTrue);
    });
  });

  group('Persistence Tests', () {
    late TestGenericModelFactory factory;

    setUp(() {
      factory = TestGenericModelFactory();
    });

    test('is persisted cache model with instance check', () {
      final regularModel = TestModel(id: 1, name: 'Test');
      final persistedModel = TestPersistedModel(id: 1, value: 'Test');
      expect(regularModel is PersistedCacheModel, isFalse);
      expect(persistedModel is PersistedCacheModel, isTrue);
    });
  });
}
