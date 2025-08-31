import 'package:flutter_model_cache/flutter_model_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() async {
  group('ModelFactory', () {
    late ModelFactory modelFactory;
    setUp(() {
      modelFactory = ModelFactory();
      modelFactory.registerHttpClient(
        MockClient((request) async {
          return http.Response('[]', 200);
        }),
      );
    });

    test('should create a model factory', () {
      expect(modelFactory, isNotNull);
    });

    group('queryModels', () {
      test('should complete successfully', () async {
        final models = await modelFactory.queryModels('models');
        expect(models, isEmpty);
      });

      group('with queryParams', () {
        test('should complete successfully', () async {
          final models = await modelFactory.queryModels(
            'models',
            queryParams: {'id': '1'},
          );
          expect(models, isEmpty);
        });
      });
    });
  });
}
