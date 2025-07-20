import 'dart:collection';

import 'package:flutter_model_cache/src/stream_state.dart';

class ModelListStream<T> extends ListBase<T> {
  final List<T> _list = [];
  String collectionName;
  StreamState streamState;

  ModelListStream({
    required this.collectionName,
    this.streamState = StreamStates.none,
    List<T>? models,
  }) {
    if (models != null) {
      _list.addAll(models);
    }
  }

  @override
  set length(int newLength) {
    _list.length = newLength;
  }

  @override
  int get length => _list.length;

  @override
  T operator [](int index) => _list[index];

  @override
  void operator []=(int index, T value) {
    _list[index] = value;
  }
}
