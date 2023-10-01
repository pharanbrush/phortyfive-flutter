import 'package:pfs2/core/phtimer.dart';
import 'package:scoped_model/scoped_model.dart';

class TimerModel extends Model {
  final Phtimer timer = Phtimer();

  void restart() {
    timer.restart();
  }

  void handleElapsed() {
    notifyListeners();
  }

  void handleTick() {
    timer.handleTick();
  }
}
