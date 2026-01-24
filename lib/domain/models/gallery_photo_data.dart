class GalleryPhotoData {
  GalleryPhotoData({
    this.id,
    this.ownerId,
    required this.aquariumId,
    this.creatureId,
    this.creatureName,
    this.imageUrl,
    this.imageFile,
    required this.photoDate,
    this.caption,
    this.created,
    this.updated,
  });

  String? id;
  String? ownerId;
  String aquariumId;
  String? creatureId;
  String? creatureName;
  String? imageUrl;
  String? imageFile;
  DateTime photoDate;
  String? caption;
  DateTime? created;
  DateTime? updated;

  GalleryPhotoData copyWith({
    String? id,
    String? ownerId,
    String? aquariumId,
    String? creatureId,
    String? creatureName,
    String? imageUrl,
    String? imageFile,
    DateTime? photoDate,
    String? caption,
    DateTime? created,
    DateTime? updated,
  }) {
    return GalleryPhotoData(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      aquariumId: aquariumId ?? this.aquariumId,
      creatureId: creatureId ?? this.creatureId,
      creatureName: creatureName ?? this.creatureName,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFile: imageFile ?? this.imageFile,
      photoDate: photoDate ?? this.photoDate,
      caption: caption ?? this.caption,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aquarium_id': aquariumId,
      'creature_id': creatureId,
      'photo_date': photoDate.toIso8601String(),
      'caption': caption,
    };
  }

  factory GalleryPhotoData.fromJson(
    Map<String, dynamic> json, {
    String? baseUrl,
  }) {
    String? imageUrl;
    if (json['image'] != null && json['id'] != null && baseUrl != null) {
      imageUrl =
          '$baseUrl/api/files/gallery_photos/${json['id']}/${json['image']}';
    }

    String? creatureName;
    if (json['expand'] != null && json['expand']['creature_id'] != null) {
      final creature = json['expand']['creature_id'] as Map<String, dynamic>;
      creatureName =
          creature['nickname'] as String? ?? creature['name'] as String?;
    }

    return GalleryPhotoData(
      id: json['id'] as String?,
      ownerId: json['owner'] as String?,
      aquariumId: json['aquarium_id'] as String,
      creatureId: json['creature_id'] as String?,
      creatureName: creatureName,
      imageUrl: imageUrl,
      photoDate: DateTime.parse(json['photo_date'] as String),
      caption: json['caption'] as String?,
      created: json['created'] != null
          ? DateTime.tryParse(json['created'] as String)
          : null,
      updated: json['updated'] != null
          ? DateTime.tryParse(json['updated'] as String)
          : null,
    );
  }
}
