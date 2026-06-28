import 'package:flutter_model_cache/flutter_model_cache.dart';
import 'package:flutter_model_cache/src/association_inverse.dart';
import 'package:flutter_test/flutter_test.dart';

// Test model classes
class Author extends Model {
  final String name;
  final InverseAssociation<Post> posts;

  Author({
    super.id,
    super.lastUpdated,
    required this.name,
    required this.posts,
  });

  static const String classCollectionName = 'authors';

  @override
  String get collectionName => classCollectionName;

  factory Author.fromJson(Map<String, Object?> json) {
    return Author(
      id: json['id'] as int?,
      lastUpdated: Model.dateTimeFromJsonOrNull(json['lastUpdated']),
      name: json['name'] as String,
      posts: InverseAssociation<Post>(
        targetCollection: Post.classCollectionName,
        sourceId: json['id'] as int,
        sourceCollection: classCollectionName,
        inverseName: 'author',
      ),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {...super.toJson(), 'name': name};
  }
}

class Post extends Model {
  final String title;
  final SingleAssociation<Author> author;

  Post({
    super.id,
    super.lastUpdated,
    required this.title,
    required this.author,
  });

  static const String classCollectionName = 'posts';

  @override
  String get collectionName => classCollectionName;

  factory Post.fromJson(Map<String, Object?> json) {
    return Post(
      id: json['id'] as int?,
      lastUpdated: Model.dateTimeFromJsonOrNull(json['lastUpdated']),
      title: json['title'] as String,
      author: SingleAssociation<Author>(
        sourceCollection: Post.classCollectionName,
        name: 'author',
        targetCollection: Author.classCollectionName,
        id: json['author_id'] as int,
        sourceId: json['id'] as int?,
      ),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {...super.toJson(), 'title': title};
  }
}

void main() {
  setUp(() {
    // Clear registry before each test
    FakeModelFactory().clear();
    AssociationRegistry().clear();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() {
    AssociationRegistry().clear();
  });

  group('InverseMultiAssociation', () {
    test('should add model and register inverse', () {
      final post1 = Post(
        id: 101,
        title: 'Post 1',
        author: SingleAssociation<Author>(
          sourceCollection: Post.classCollectionName,
          targetCollection: Author.classCollectionName,
          name: 'author',
          id: 1,
          sourceId: 101,
        ),
      );
      final post2 = Post(
        id: 102,
        title: 'Post 2',
        author: SingleAssociation<Author>(
          sourceCollection: Post.classCollectionName,
          targetCollection: Author.classCollectionName,
          name: 'author',
          id: 1,
          sourceId: 102,
        ),
      );

      final author = Author(
        id: 1,
        name: 'John',
        posts: InverseAssociation<Post>(
          sourceCollection: Author.classCollectionName,
          sourceId: 1,
          targetCollection: Post.classCollectionName,
          inverseName: 'author',
        ),
      );
      post1.save();
      post2.save();
      author.save();
      final peekPosts = author.posts.peek;
      expect(peekPosts.length, 2);
    });
  });
}
