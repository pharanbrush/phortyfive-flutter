class Circulator {
  final reorderedIndices = List<int>.empty(growable: true);
  int _currentNumber = 0;

  int get count => reorderedIndices.length;
  bool get isPopulated => count > 0;

  int get currentIndex => isPopulated ? reorderedIndices[_currentNumber] : 0;
  int get maxNumber => count - 1;

  void moveNext() => moveCurrentNumberBy(1);
  void movePrevious() => moveCurrentNumberBy(-1);

  void startNewOrder(int count) {
    if (count <= 0) {
      clear();
      return;
    }

    resetToDefaultOrder(count);
    _generateShuffledOrder();
    setCurrentNumber(0);
  }

  void resetToDefaultOrder(int count) {
    reorderedIndices.clear();
    for (var i = 0; i < count; i++) {
      reorderedIndices.add(i);
    }
  }

  void _generateShuffledOrder() {
    reorderedIndices.shuffle();
  }

  void clear() {
    reorderedIndices.clear();
    setCurrentNumber(0);
  }

  void setCurrentNumber(int newNumber) {
    _currentNumber = newNumber;
  }

  void moveCurrentNumberBy(int increment) {
    final possibleNewNumber = _getIncrementedIndex(_currentNumber, increment);
    if (possibleNewNumber == null) return;

    setCurrentNumber(possibleNewNumber);
  }

  int? _getIncrementedIndex(int current, int increment) {
    if (reorderedIndices.isEmpty) return null;
    if (increment.abs() > reorderedIndices.length) return null;

    int newNumber = _currentNumber + increment;
    if (newNumber >= count) newNumber -= count;
    if (newNumber < 0) newNumber += count;

    return newNumber;
  }

  int? getSurroundingIndex(int increment) {
    final possibleNewNumber = _getIncrementedIndex(_currentNumber, increment);
    if (possibleNewNumber == null) return null;

    return reorderedIndices[possibleNewNumber];
  }
}
