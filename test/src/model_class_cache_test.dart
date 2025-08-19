import 'package:flutter_model_cache/flutter_model_cache.dart';
import 'package:flutter_model_cache/src/model_class_cache.dart';
import 'package:flutter_test/flutter_test.dart';

class TestModel extends Model {
  TestModel({super.id});
  @override
  String get collectionName => 'tests';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModelClassCache', () {
    test('add and peek', () {
      final cache = ModelClassCache<TestModel?>('tests');
      final model = TestModel(id: 1);
      cache.add(model);
      expect(cache.peek(1), model);
    });

    test('add fromQuery only shows for query by id', () {
      final cache = ModelClassCache<TestModel?>('tests');
      cache.add(TestModel(id: 1), fromQuery: true);
      expect(cache.peekAll(), isEmpty);
      expect(cache.peek(1)?.id, 1);
    });

    test('removeById removes model', () {
      final cache = ModelClassCache<TestModel?>('tests');
      final model = TestModel(id: 1);
      cache.add(model);
      expect(cache.removeById(1), model);
      expect(cache.peek(1), isNull);
    });

    test('remove removes model', () {
      final cache = ModelClassCache<TestModel?>('tests');
      final model = TestModel(id: 1);
      cache.add(model);
      expect(cache.remove(model), model);
      expect(cache.peek(1), isNull);
    });

    test('clear empties caches', () {
      final cache = ModelClassCache<TestModel?>('tests');
      cache.add(TestModel(id: 1));
      cache.clear();
      expect(cache.peekAll(), isEmpty);
    });

    test('replaceAll populates cache', () {
      final cache = ModelClassCache<TestModel?>('tests');
      cache.replaceAll([TestModel(id: 1), TestModel(id: 2)]);
      expect(cache.peekAll().length, 2);
    });

    test('operator index get/set', () {
      final cache = ModelClassCache<TestModel?>('tests');
      final model = TestModel(id: 1);
      cache[1] = model;
      expect(cache[1], model);
    });

    test('forEach iterates over values', () {
      final cache = ModelClassCache<TestModel?>('tests');
      cache.replaceAll([TestModel(id: 1), TestModel(id: 2)]);
      var count = 0;
      cache.forEach((_) => count++);
      expect(count, 2);
    });

    test('peek returns query models', () {
      final cache = ModelClassCache<TestModel?>('tests');
      cache.add(TestModel(id: 1), fromQuery: true);
      expect(cache.peek(1)?.id, 1);
    });

    test('stream is not loaded until add', () {
      final cache = ModelClassCache<TestModel?>('tests');
      cache.updateStreamController();
      expect(cache.loaded, false);
      cache.add(TestModel(id: 1));
      expect(cache.loaded, true);
    });

    test('stream emits list on add', () {
      final cache = ModelClassCache<TestModel?>('tests');
      final stream = cache.streamController().stream;
      expectLater(
        stream,
        emits(isA<List<TestModel?>>().having((l) => l.length, 'len', 1)),
      );
      cache.add(TestModel(id: 1));
    });

    test('model list stream emits on add', () {
      final cache = ModelClassCache<TestModel?>('tests');
      final stream = cache.modelListStreamController().stream;
      expectLater(
        stream,
        emits(
          isA<ModelListStream<TestModel?>>()
              .having((e) => e.length, 'len', 1)
              .having((e) => e.streamState, 'state', StreamStates.loaded)
              .having((e) => e.collectionName, 'col', 'tests'),
        ),
      );
      cache.add(TestModel(id: 1));
    });

    test('stream for id emits current model on listen', () {
      final cache = ModelClassCache<TestModel?>('tests');
      final model = TestModel(id: 1);
      cache.add(model);
      expectLater(cache.streamControllerForId(1).stream, emits(model));
    });
  });
}
