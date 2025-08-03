class IdGenerator {
  static int _idSequence = 0;
  static final IdGenerator _idGenerator = IdGenerator._internal();

  factory IdGenerator() {
    return _idGenerator;
  }

  int newId() {
    _idSequence++;
    return _idSequence;
  }

  IdGenerator._internal();
}
