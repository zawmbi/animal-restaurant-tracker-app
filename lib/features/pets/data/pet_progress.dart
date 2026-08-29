import '../../shared/data/unlocked_store.dart';

class PetProgress {
  PetProgress._();
  static final PetProgress instance = PetProgress._();

  final _store = UnlockedStore.instance;

  // Buckets
  static const String _ownedBucket = 'pet_owned';
  static const String _matureBucket = 'pet_mature';
  static const String _roomBucket = 'pet_room_unlocked';
  static const String _photoBucket = 'pet_photo_task_done';

  bool isOwned(String petId) => _store.isUnlocked(_ownedBucket, petId);
  bool isMature(String petId) => _store.isUnlocked(_matureBucket, petId);

  Future<void> setOwned(String petId, bool v) =>
      _store.setUnlocked(_ownedBucket, petId, v);

  Future<void> setMature(String petId, bool v) =>
      _store.setUnlocked(_matureBucket, petId, v);

  bool isRoomUnlocked(String roomId) => _store.isUnlocked(_roomBucket, roomId);
  Future<void> setRoomUnlocked(String roomId, bool v) =>
      _store.setUnlocked(_roomBucket, roomId, v);

  bool isPhotoTaskDone(String taskId) => _store.isUnlocked(_photoBucket, taskId);
  Future<void> setPhotoTaskDone(String taskId, bool v) =>
      _store.setUnlocked(_photoBucket, taskId, v);

  // Bulk writes go through setManyUnlocked: one persist + one notify for the
  // whole batch instead of one per id.

  Future<void> setAllOwned(bool v, List<String> petIds) =>
      _store.setManyUnlocked(_ownedBucket, petIds, v);

  Future<void> setAllMature(bool v, List<String> petIds) =>
      _store.setManyUnlocked(_matureBucket, petIds, v);

  Future<void> setAllRooms(bool v, List<String> roomIds) =>
      _store.setManyUnlocked(_roomBucket, roomIds, v);

  Future<void> setAllPhotoTasks(bool v, List<String> taskIds) =>
      _store.setManyUnlocked(_photoBucket, taskIds, v);
}
