/// 갤러리 사진 데이터 모델
class GalleryPhotoData {
  GalleryPhotoData({
    this.id,
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

  /// PocketBase record ID
  String? id;

  /// 어항 ID (FK)
  String aquariumId;

  /// 생물 ID (FK, optional - 생물 태그)
  String? creatureId;

  /// 생물 이름 (expand로 가져온 경우)
  String? creatureName;

  /// 이미지 URL (서버)
  String? imageUrl;

  /// 이미지 파일 경로 (로컬, 업로드 전)
  String? imageFile;

  /// 촬영일
  DateTime photoDate;

  /// 캡션/설명
  String? caption;

  /// 생성일시
  DateTime? created;

  /// 수정일시
  DateTime? updated;

  GalleryPhotoData copyWith({
    String? id,
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

  /// PocketBase JSON으로 변환 (파일 제외)
  Map<String, dynamic> toJson() {
    return {
      'aquarium_id': aquariumId,
      'creature_id': creatureId,
      'photo_date': photoDate.toIso8601String(),
      'caption': caption,
    };
  }

  /// PocketBase JSON에서 생성
  factory GalleryPhotoData.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    // image 필드 처리
    String? imageUrl;
    if (json['image'] != null && json['id'] != null && baseUrl != null) {
      imageUrl = '$baseUrl/api/files/gallery_photos/${json['id']}/${json['image']}';
    }

    // expand된 creature 정보 처리
    String? creatureName;
    if (json['expand'] != null && json['expand']['creature_id'] != null) {
      final creature = json['expand']['creature_id'] as Map<String, dynamic>;
      creatureName = creature['nickname'] as String? ?? creature['name'] as String?;
    }

    return GalleryPhotoData(
      id: json['id'] as String?,
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
