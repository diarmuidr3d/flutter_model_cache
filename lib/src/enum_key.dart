class EnumKey {
  const EnumKey(this.name);

  final String name;

  @override
  bool operator ==(Object other) {
    return other is EnumKey &&
        other.runtimeType == runtimeType &&
        other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
