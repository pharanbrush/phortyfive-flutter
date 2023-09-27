import 'package:pfs2/core/timer.dart';
import 'package:scoped_model/scoped_model.dart';

class TimerModel extends Model {
  final Timer timer = Timer();

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
