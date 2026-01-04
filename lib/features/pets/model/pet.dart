class Pet {
  final String id;
  final String hatchlingName;
  final String matureName;
  final String nickname;
  final List<String> likes;
  final List<int> series;

  const Pet({
    required this.id,
    required this.hatchlingName,
    required this.matureName,
    required this.nickname,
    required this.likes,
    required this.series,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      hatchlingName: json['hatchlingName'] as String,
      matureName: json['matureName'] as String,
      nickname: json['nickname'] as String,
      likes: (json['likes'] as List<dynamic>).cast<String>(),
      series: (json['series'] as List<dynamic>).map((e) => e as int).toList(),
    );
  }
}

class PetRoom {
  final String id;
  final String name;
  final String currency;
  final int amount;
  final int requiresPets;

  const PetRoom({
    required this.id,
    required this.name,
    required this.currency,
    required this.amount,
    required this.requiresPets,
  });

  factory PetRoom.fromJson(Map<String, dynamic> json) {
    final price = json['price'] as Map<String, dynamic>;
    return PetRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      currency: (price['currency'] as String),
      amount: (price['amount'] as num).toInt(),
      requiresPets: (json['requiresPets'] as num).toInt(),
    );
  }
}

class PetPhotoTaskReward {
  final String? currency;
  final int? amount;
  final String? item;

  const PetPhotoTaskReward({this.currency, this.amount, this.item});

  factory PetPhotoTaskReward.fromJson(Map<String, dynamic> json) {
    return PetPhotoTaskReward(
      currency: json['currency'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      item: json['item'] as String?,
    );
  }
}

class PetPhotoTask {
  final String id;
  final List<String> pets;
  final List<String> furniture;
  final List<PetPhotoTaskReward> rewards;

  const PetPhotoTask({
    required this.id,
    required this.pets,
    required this.furniture,
    required this.rewards,
  });

  factory PetPhotoTask.fromJson(Map<String, dynamic> json) {
    return PetPhotoTask(
      id: json['id'] as String,
      pets: (json['pets'] as List<dynamic>).cast<String>(),
      furniture: (json['furniture'] as List<dynamic>).cast<String>(),
      rewards: (json['rewards'] as List<dynamic>)
          .map((e) => PetPhotoTaskReward.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PetsData {
  final String updatedInVersion;
  final String petRoomsUpdatedInVersion;

  final int ratingRequired;
  final String notes;

  final List<PetRoom> rooms;
  final List<PetPhotoTask> photoTasks;
  final List<Pet> pets;

  const PetsData({
    required this.updatedInVersion,
    required this.petRoomsUpdatedInVersion,
    required this.ratingRequired,
    required this.notes,
    required this.rooms,
    required this.photoTasks,
    required this.pets,
  });

  factory PetsData.fromJson(Map<String, dynamic> json) {
    final unlocking = json['unlocking'] as Map<String, dynamic>;
    return PetsData(
      updatedInVersion: json['updatedInVersion'] as String,
      petRoomsUpdatedInVersion: json['petRoomsUpdatedInVersion'] as String,
      ratingRequired: (unlocking['ratingRequired'] as num).toInt(),
      notes: (unlocking['notes'] as String?) ?? '',
      rooms: (json['petRooms'] as List<dynamic>)
          .map((e) => PetRoom.fromJson(e as Map<String, dynamic>))
          .toList(),
      photoTasks: (json['photoTasks'] as List<dynamic>)
          .map((e) => PetPhotoTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      pets: (json['pets'] as List<dynamic>)
          .map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
