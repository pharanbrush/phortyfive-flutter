class Circulator {
  final reorderedIndices = List<int>.empty(growable: true);
  int currentNumber = 0;

  int getCount() => reorderedIndices.length;
  bool isPopulated() => getCount() > 0;

  int getCurrentIndex() =>
      isPopulated() ? reorderedIndices[currentNumber] : 0;
  int getMaxNumber() => getCount() - 1;

  void moveNext() => moveCurrentNumberBy(1);
  void movePrevious() => moveCurrentNumberBy(-1);

  void startNewOrder(int count) {
    if (count <= 0) {
      clear();
      return;
    }

    resetToDefaultOrder(count);
    generateShuffledOrder();
    setCurrentNumber(0);
  }

  void resetToDefaultOrder(int count) {
    reorderedIndices.clear();
    for (var i = 0; i < count; i++) {
      reorderedIndices.add(i);
    }
  }
  
  void generateShuffledOrder() {    
    reorderedIndices.shuffle();
  }

  void clear() {
    reorderedIndices.clear();
    setCurrentNumber(0);
  }

  void setCurrentNumber(int newNumber) {
    currentNumber = newNumber;
    //event OnCurrentNumberChanged
  }

  void moveCurrentNumberBy(int increment) {
    int newNumber = currentNumber + increment;

    final max = getMaxNumber();
    if (newNumber > max) newNumber = 0;
    if (newNumber < 0) newNumber = max;

    setCurrentNumber(newNumber);
  }  
  
}
