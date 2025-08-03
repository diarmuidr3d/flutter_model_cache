# Flutter Model Cache

A powerful local caching system for Flutter applications that work with JSON APIs. This package provides automatic model caching, reactive programming with streams, local persistence, and seamless HTTP operations.

## Features

- 🚀 **Automatic Model Caching** - In-memory caching with automatic lifecycle management
- 🔄 **Reactive Programming** - Stream-based updates for real-time UI synchronization  
- 💾 **Local Persistence** - Secure local storage with `flutter_secure_storage`
- 🌐 **HTTP Integration** - Built-in CRUD operations over REST APIs
- 🔗 **Model Associations** - Support for single and multi-model relationships
- 📊 **Stream States** - Loading, reloading, and loaded states for better UX
- 🎯 **Type Safety** - Full generic type support throughout the API

[![Test](https://github.com/diarmuidr3d/flutter_model_cache/actions/workflows/flutter_build.yml/badge.svg)](https://github.com/diarmuidr3d/flutter_model_cache/actions/workflows/flutter_build.yml) [![Publish](https://github.com/diarmuidr3d/flutter_model_cache/actions/workflows/publish.yml/badge.svg)](https://github.com/diarmuidr3d/flutter_model_cache/actions/workflows/publish.yml) ![Pub](https://img.shields.io/pub/v/flutter_token_auth)

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_model_cache: ^0.0.4
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Define Your Model

```dart
import 'package:flutter_model_cache/flutter_model_cache.dart';

class Animal extends Model {
  final String name;
  final String species;
  
  Animal({
    required this.name, 
    required this.species,
    super.id,
    super.lastUpdated,
  });

  static const String classCollectionName = 'animals';
  
  @override
  String get collectionName => classCollectionName;

  factory Animal.fromJson(Map<String, Object?> json) {
    return Animal(
      name: json['name'] as String,
      species: json['species'] as String,
      id: json['id'] as int?,
      lastUpdated: Model.dateTimeFromJsonOrNull(json['lastUpdated']),
    );
  }
  
  @override
  Map<String, Object?> toJson() {
    return {
      ...super.toJson(),
      'name': name,
      'species': species,
    };
  }
}
```

### 2. Register Your Model
You should do this during app setup for all your models.
```dart
void main() async {
  final modelFactory = ModelFactory();
  
  // Register model class with factory
  modelFactory.registerModelClass(
    Animal.classCollectionName,
    (json) => Animal.fromJson(json),
  );
  
  runApp(MyApp());
}
```

### 3. Use Your Models

```dart
// Find all animals (retrieve them from the server)
Future<List<Animal>> getAllAnimals() async {
return await ModelFactory().findModels<Animal>(Animal.classCollectionName);
}

// Find specific animal
Future<Animal?> getAnimal(int id) async {
return await ModelFactory().findModel<Animal>(Animal.classCollectionName, id);
}

// Save animal
Future<Animal> saveAnimal(Animal animal) async {
return await animal.save<Animal>();
}

// Delete animal
Future<Animal?> deleteAnimal(Animal animal) async {
return await animal.delete<Animal>();
}
```

## Reactive Programming with Streams

### Stream Individual Models

```dart
class AnimalDetailWidget extends StatelessWidget {
  final int animalId;
  
  const AnimalDetailWidget({required this.animalId});
  
  @override
  Widget build(BuildContext context) {
    final modelFactory = ModelFactory();
    
    return StreamBuilder<Animal?>(
      stream: modelFactory.findAndStreamModel<Animal>(
        Animal.classCollectionName, 
        animalId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        final animal = snapshot.data;
        if (animal == null) {
          return Text('Animal not found');
        }
        
        return Column(
          children: [
            Text('Name: ${animal.name}'),
            Text('Species: ${animal.species}'),
          ],
        );
      },
    );
  }
}
```

### Stream Model Collections

```dart
class AnimalListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final modelFactory = ModelFactory();
    
    return StreamBuilder<List<Animal>>(
      stream: modelFactory.findAndStreamModels<Animal>(
        Animal.classCollectionName,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        final animals = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final animal = animals[index];
            return ListTile(
              title: Text(animal.name),
              subtitle: Text(animal.species),
            );
          },
        );
      },
    );
  }
}
```

### Stream with Loading States

```dart
class AnimalListWithStatesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final modelFactory = ModelFactory();
    
    return StreamBuilder<ModelListStream<Animal>>(
      stream: modelFactory.findAndModelListStreamModels<Animal>(
        Animal.classCollectionName,
      ),
      builder: (context, snapshot) {
        final modelListStream = snapshot.data;
        
        if (modelListStream?.streamState == StreamStates.loading) {
          return CircularProgressIndicator();
        }
        
        if (modelListStream?.streamState == StreamStates.reloading) {
          return Column(
            children: [
              LinearProgressIndicator(),
              Expanded(child: _buildList(modelListStream)),
            ],
          );
        }
        
        return _buildList(modelListStream);
      },
    );
  }
  
  Widget _buildList(ModelListStream<Animal>? animals) {
    if (animals == null || animals.isEmpty) {
      return Text('No animals found');
    }
    
    return ListView.builder(
      itemCount: animals.length,
      itemBuilder: (context, index) {
        final animal = animals[index];
        return ListTile(
          title: Text(animal.name),
          subtitle: Text(animal.species),
        );
      },
    );
  }
}
```

## Model Associations

### Single Associations

```dart
class Post extends Model {
  final String title;
  final String content;
  final SingleAssociation<User> author;
  
  Post({
    required this.title,
    required this.content,
    required this.author,
    super.id,
    super.lastUpdated,
  });

  static const String classCollectionName = 'posts';
  
  @override
  String get collectionName => classCollectionName;

  factory Post.fromJson(Map<String, Object?> json) {
    return Post(
      title: json['title'] as String,
      content: json['content'] as String,
      author: SingleAssociation.fromJson(
        User.classCollectionName,
        json['author'] as Map<String, Object?>,
      ),
      id: json['id'] as int?,
      lastUpdated: Model.dateTimeFromJsonOrNull(json['lastUpdated']),
    );
  }
}

// Usage
class PostWidget extends StatelessWidget {
  final Post post;
  
  const PostWidget({required this.post});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(post.title),
        Text(post.content),
        StreamBuilder<User?>(
          stream: post.author.findAndStream,
          builder: (context, snapshot) {
            final author = snapshot.data;
            return Text('By: ${author?.name ?? 'Loading...'}');
          },
        ),
      ],
    );
  }
}
```

## Advanced Usage

### Custom HTTP Client

```dart
void main() {
  final modelFactory = ModelFactory();
  
  // Register custom HTTP client for authentication, logging, etc.
  modelFactory.registerHttpClient(
    AuthenticatedHttpClient(), // Your custom http.BaseClient
  );
}
```

### Querying with Parameters

```dart
Future<List<Animal>> getAnimalsBySpecies(String species) async {
  final modelFactory = ModelFactory();
  
  return await modelFactory.queryModels<Animal>(
    Animal.classCollectionName,
    queryParams: {'species': species},
  );
}
```

### Peek Without Network Calls

```dart
// Get cached model without triggering network request
Animal? getCachedAnimal(int id) {
  final modelFactory = ModelFactory();
  
  return modelFactory.peekModel<Animal>(
    collection: Animal.classCollectionName,
    id: id,
  );
}

// Get all cached models
List<Animal> getAllCachedAnimals() {
  final modelFactory = ModelFactory();
  
  return modelFactory.peekModels<Animal>(
    collection: Animal.classCollectionName,
  );
}
```

## API Reference

### Model

Base class for all cached models.

**Properties:**
- `int? id` - Unique identifier
- `DateTime lastUpdated` - Last modification timestamp
- `bool deleted` - Deletion flag
- `String collectionName` - Collection identifier (abstract)

**Methods:**
- `Future<T> save<T>()` - Save model to server and cache
- `Future<T?> delete<T>()` - Delete model from server and cache
- `Future<T> reload<T>()` - Reload model from server
- `Map<String, Object?> toJson()` - Serialize to JSON

### ModelFactory

Singleton factory for model operations.

**Key Methods:**
- `registerModelClass<T>(String, ModelFromJson<T>)` - Register model type
- `Future<T?> findModel<T>(String, int)` - Find single model
- `Future<List<T>> findModels<T>(String)` - Find all models  
- `Future<List<T>> queryModels<T>(String, {Map<String, dynamic>?})` - Query with parameters
- `Stream<T?> findAndStreamModel<T>(String, int)` - Stream single model
- `Stream<List<T>> findAndStreamModels<T>(String)` - Stream model list
- `T? peekModel<T>({required String, required int})` - Get cached model
- `List<T> peekModels<T>({required String})` - Get cached models

### Stream States

Available stream states for loading management:

- `StreamStates.none` - No operation
- `StreamStates.loading` - Initial load
- `StreamStates.reloading` - Refresh operation  
- `StreamStates.loaded` - Load completed

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
