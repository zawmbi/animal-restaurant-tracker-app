import '../../shared/data/unlocked_store.dart';

class AromaticAcornProgress {
  AromaticAcornProgress._();
  static final AromaticAcornProgress instance = AromaticAcornProgress._();

  static const String _type = 'acorn'; // bucket name in UnlockedStore

  final _store = UnlockedStore.instance;

  Future<void> _ensureType() async {
    // safe to call repeatedly
    await _store.registerType(_type);
  }

  String _reqId(String stageId, int i) => 'stage:$stageId:req:$i';
  String _taskId(String stageId, int i) => 'stage:$stageId:task:$i';

  bool isReqChecked(String stageId, int index) {
    return _store.isUnlocked(_type, _reqId(stageId, index));
  }

  bool isTaskChecked(String stageId, int index) {
    return _store.isUnlocked(_type, _taskId(stageId, index));
  }

  Future<void> setReqChecked(String stageId, int index, bool v) async {
    await _ensureType();
    await _store.setUnlocked(_type, _reqId(stageId, index), v);
  }

  Future<void> setTaskChecked(String stageId, int index, bool v) async {
    await _ensureType();
    await _store.setUnlocked(_type, _taskId(stageId, index), v);
  }

  Future<void> setAllForStage({
    required String stageId,
    required int reqCount,
    required int taskCount,
    required bool value,
  }) async {
    await _ensureType();
    for (int i = 0; i < reqCount; i++) {
      await _store.setUnlocked(_type, _reqId(stageId, i), value);
    }
    for (int i = 0; i < taskCount; i++) {
      await _store.setUnlocked(_type, _taskId(stageId, i), value);
    }
  }

  bool stageComplete({
    required String stageId,
    required int reqCount,
    required int taskCount,
  }) {
    for (int i = 0; i < reqCount; i++) {
      if (!isReqChecked(stageId, i)) return false;
    }
    for (int i = 0; i < taskCount; i++) {
      if (!isTaskChecked(stageId, i)) return false;
    }
    return true;
  }

  int stageCheckedCount({
    required String stageId,
    required int reqCount,
    required int taskCount,
  }) {
    int c = 0;
    for (int i = 0; i < reqCount; i++) {
      if (isReqChecked(stageId, i)) c++;
    }
    for (int i = 0; i < taskCount; i++) {
      if (isTaskChecked(stageId, i)) c++;
    }
    return c;
  }
}
