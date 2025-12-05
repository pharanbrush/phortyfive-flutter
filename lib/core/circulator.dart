/// [Circulator] generates a reordered list of indices and keeps track of a "current" value.
/// This allows a shuffled order access by keeping track of a lookup table of shuffled indices
/// instead of shuffling the source list.
class Circulator with IndexCursor {
  final outputIndices = <int>[];

  @override
  int get count => outputIndices.length;

  bool get isPopulated => outputIndices.isNotEmpty;

  int get currentOutputIndex =>
      isPopulated ? outputIndices[_currentInputIndex] : 0;

  void startNewOrder(int count) {
    if (count <= 0) {
      clear();
      return;
    }

    void resetToDefaultOrder(int count) {
      outputIndices.clear();
      for (int i = 0; i < count; i++) {
        outputIndices.add(i);
      }
    }

    void generateShuffledOrder() {
      outputIndices.shuffle();
    }

    resetToDefaultOrder(count);
    generateShuffledOrder();
    resetCurrentInputIndex();
  }

  void clear() {
    outputIndices.clear();
    resetCurrentInputIndex();
  }

  int? getSurroundingOutputIndex(int increment) {
    final possibleNewInputIndex =
        _getIncrementedInputIndex(_currentInputIndex, increment);
    if (possibleNewInputIndex == null) return null;

    return outputIndices[possibleNewInputIndex];
  }
}

mixin IndexCursor {
  int _currentInputIndex = 0;

  int get count;

  int get maxInputIndex => count - 1;

  void moveNext() => moveCurrentInputIndexBy(1);
  void movePrevious() => moveCurrentInputIndexBy(-1);

  void resetCurrentInputIndex() {
    setCurrentInputIndex(0);
  }

  void setCurrentInputIndex(int newNumber) {
    _currentInputIndex = newNumber;
  }

  int? _getIncrementedInputIndex(int currentInput, int increment) {
    final count = this.count;
    if (count == 0) return null;
    if (increment.abs() > count) return null;

    int newInputIndex = currentInput + increment;
    if (newInputIndex >= count) newInputIndex -= count;
    if (newInputIndex < 0) newInputIndex += count;

    return newInputIndex;
  }

  void moveCurrentInputIndexBy(int increment) {
    final possibleNewInputIndex =
        _getIncrementedInputIndex(_currentInputIndex, increment);
    if (possibleNewInputIndex == null) return;

    setCurrentInputIndex(possibleNewInputIndex);
  }
}
