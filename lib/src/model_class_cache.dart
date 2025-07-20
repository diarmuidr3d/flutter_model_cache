import 'dart:async';

import 'model.dart';
import 'model_list_stream.dart';
import 'stream_state.dart';

class ModelClassCache<T extends Model?> {
  ModelClassCache(this.collectionName);

  final Map<int, T> modelCache = {};
  final Map<int, T> queryModelCache = {};
  StreamController<ModelListStream<T>>? _modelListStreamController;
  StreamController<List<T>>? _streamController;
  final Map<int, StreamController<T?>?> _streamControllersForId = {};
  final String collectionName;
  bool _modelListStreamControllerListened = false;
  bool _streamControllerListened = false;
  bool loaded = false;

  T add(T model, {bool fromQuery = false}) {
    if (model == null) return model;
    if (fromQuery && modelCache[model.id!] == null) {
      return _addQueryModel(model);
    }
    loaded = true;
    modelCache[model.id!] = model;
    updateStreamController();
    _updateStreamControllerForId(model.id!);
    return model;
  }

  T remove(T model) {
    if (model == null) return model;
    removeById(model.id!);
    return model;
  }

  T? removeById(int id) {
    final model = modelCache[id] ?? queryModelCache[id];
    modelCache.remove(id);
    queryModelCache.remove(id);
    updateStreamController();
    _updateStreamControllerForId(id);
    return model;
  }

  T? peek(int id) {
    return modelCache[id] ?? queryModelCache[id];
  }

  List<T> peekAll() {
    return modelCache.values.toList();
  }

  T _addQueryModel(T model) {
    if (model == null) return model;
    queryModelCache[model.id!] = model;
    return model;
  }

  void clear() {
    modelCache.clear();
    queryModelCache.clear();
    updateStreamController();
    _streamControllersForId.forEach((id, sc) {
      sc?.add(null);
    });
  }

  void replaceAll(List<T> models) {
    modelCache.clear();
    for (var model in models) {
      add(model);
    }
    updateStreamController();
  }

  void _onListenToModelListStream() {
    _modelListStreamControllerListened = true;
    updateStreamController();
  }

  void _onCancelModelListStream() {
    _modelListStreamControllerListened = false;
  }

  StreamController<ModelListStream<T>> modelListStreamController() {
    _modelListStreamController ??=
        StreamController<ModelListStream<T>>.broadcast(
            onListen: _onListenToModelListStream,
            onCancel: _onCancelModelListStream);
    return _modelListStreamController!;
  }

  void _onListenToStream() {
    _streamControllerListened = true;
    updateStreamController();
  }

  void _onCancelStream() {
    _streamControllerListened = false;
  }

  StreamController<List<T>> streamController() {
    _streamController ??= StreamController<List<T>>.broadcast(
        onListen: _onListenToStream, onCancel: _onCancelStream);
    return _streamController!;
  }

  StreamController<T?> streamControllerForId(int id) {
    _streamControllersForId[id] ??= StreamController<T?>.broadcast(
        onListen: () => _updateStreamControllerForId(id));
    return _streamControllersForId[id]!;
  }

  void updateStreamController({StreamState? streamState}) {
    if (_modelListStreamController != null &&
        _modelListStreamControllerListened) {
      streamState ??= loaded ? StreamStates.loaded : StreamStates.loading;
      _modelListStreamController!.add(ModelListStream<T>(
          collectionName: collectionName,
          models: modelCache.values.toList(),
          streamState: streamState));
    }
    if (_streamController != null && _streamControllerListened) {
      _streamController!.add(modelCache.values.toList());
    }
  }

  void _updateStreamControllerForId(int id) {
    final controller = _streamControllersForId[id];
    if (controller == null || !controller.hasListener) return;
    controller.add(peek(id));
  }

  T? operator [](int i) => peek(i);

  void operator []=(int i, T value) => add(value);

  void forEach(void Function(T element) action) {
    for (T element in modelCache.values) {
      action(element);
    }
  }
}
