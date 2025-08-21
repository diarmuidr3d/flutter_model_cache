import 'package:flutter_model_cache/flutter_model_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fake model_factory', () {
    test('findModels marks cache as loaded even if no models', () {
      final modelFactory = FakeModelFactory();
      modelFactory.findModels('tests');
      expect(modelFactory.modelCache['tests']?.loaded, true);
    });
  });
}
