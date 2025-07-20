import 'package:flutter_model_cache/src/enum_key.dart';

class StreamState extends EnumKey {
  const StreamState(super.name);
}

abstract class StreamStates {
  static const none = StreamState('none');
  static const loading = StreamState('loading');
  static const reloading = StreamState('reloading');
  static const loaded = StreamState('loaded');
}
