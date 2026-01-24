enum CreatureGender {
  male('수'),
  female('암'),
  mixed('혼합'),
  unknown('미상');

  const CreatureGender(this.label);
  final String label;

  String get value => name;

  static CreatureGender? fromValue(String? value) {
    if (value == null) return null;
    return CreatureGender.values.where((e) => e.name == value).firstOrNull;
  }
}

class CreatureMemoData {
  CreatureMemoData({
    this.id,
    required this.creatureId,
    required this.content,
    this.created,
    this.updated,
  });

  /// PocketBase record ID
  String? id;

  /// 생물 ID (FK)
  String creatureId;

  /// 메모 내용 (500자 제한)
  String content;

  /// 생성일시
  DateTime? created;

  /// 수정일시
  DateTime? updated;

  CreatureMemoData copyWith({
    String? id,
    String? creatureId,
    String? content,
    DateTime? created,
    DateTime? updated,
  }) {
    return CreatureMemoData(
      id: id ?? this.id,
      creatureId: creatureId ?? this.creatureId,
      content: content ?? this.content,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  /// PocketBase JSON으로 변환
  Map<String, dynamic> toJson() {
    return {'creature_id': creatureId, 'content': content};
  }

  /// PocketBase JSON에서 생성
  factory CreatureMemoData.fromJson(Map<String, dynamic> json) {
    return CreatureMemoData(
      id: json['id'] as String?,
      creatureId: json['creature_id'] as String,
      content: json['content'] as String,
      created: json['created'] != null
          ? DateTime.tryParse(json['created'] as String)
          : null,
      updated: json['updated'] != null
          ? DateTime.tryParse(json['updated'] as String)
          : null,
    );
  }
}

class CreatureData {
  CreatureData({
    this.id,
    this.ownerId,
    required this.aquariumId,
    this.catalogId,
    required this.name,
    required this.type,
    this.nickname,
    this.adoptionDate,
    this.unknownAdoptionDate = false,
    this.quantity = 1,
    this.gender,
    this.source,
    this.price,
    this.photoUrls = const [],
    this.photoFiles = const [],
    this.memos = const [],
    this.created,
    this.updated,
  });

  String? id;
  String? ownerId;
  String aquariumId;

  String? catalogId;

  /// 종류명 (예: "플라캇 베타")
  String name;

  /// 종류
  String type;

  /// 별명 (예: "호동이")
  String? nickname;

  /// 입양일
  DateTime? adoptionDate;

  /// 입양일 모름 여부
  bool unknownAdoptionDate;

  /// 마릿수
  int quantity;

  /// 성별
  CreatureGender? gender;

  /// 출처
  String? source;

  /// 분양가
  String? price;

  /// 사진 URL 목록 (서버)
  List<String> photoUrls;

  /// 사진 파일 경로 목록 (로컬, 업로드 전)
  List<String> photoFiles;

  /// 메모 목록
  List<CreatureMemoData> memos;

  /// 생성일시
  DateTime? created;

  /// 수정일시
  DateTime? updated;

  /// D+일 계산
  int? get daysFromAdoption {
    if (adoptionDate == null) return null;
    return DateTime.now().difference(adoptionDate!).inDays;
  }

  /// D+일 표시 문자열
  String get daysDisplayText {
    final days = daysFromAdoption;
    if (days == null) return '';
    return 'D+$days';
  }

  /// 표시 이름 (별명 우선)
  String get displayName => nickname ?? name;

  CreatureData copyWith({
    String? id,
    String? ownerId,
    String? aquariumId,
    String? catalogId,
    String? name,
    String? type,
    String? nickname,
    DateTime? adoptionDate,
    bool? unknownAdoptionDate,
    int? quantity,
    CreatureGender? gender,
    String? source,
    String? price,
    List<String>? photoUrls,
    List<String>? photoFiles,
    List<CreatureMemoData>? memos,
    DateTime? created,
    DateTime? updated,
  }) {
    return CreatureData(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      aquariumId: aquariumId ?? this.aquariumId,
      catalogId: catalogId ?? this.catalogId,
      name: name ?? this.name,
      type: type ?? this.type,
      nickname: nickname ?? this.nickname,
      adoptionDate: adoptionDate ?? this.adoptionDate,
      unknownAdoptionDate: unknownAdoptionDate ?? this.unknownAdoptionDate,
      quantity: quantity ?? this.quantity,
      gender: gender ?? this.gender,
      source: source ?? this.source,
      price: price ?? this.price,
      photoUrls: photoUrls ?? this.photoUrls,
      photoFiles: photoFiles ?? this.photoFiles,
      memos: memos ?? this.memos,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  /// PocketBase JSON으로 변환 (파일 제외)
  Map<String, dynamic> toJson() {
    return {
      'aquarium_id': aquariumId,
      'catalog_id': catalogId,
      'name': name,
      'type': type,
      'nickname': nickname,
      'adoption_date': adoptionDate?.toIso8601String(),
      'unknown_adoption_date': unknownAdoptionDate,
      'quantity': quantity,
      'gender': gender?.value,
      'source': source,
      'price': price,
    };
  }

  /// PocketBase JSON에서 생성
  factory CreatureData.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    // photos 필드 처리
    List<String> photoUrls = [];
    if (json['photos'] != null && json['id'] != null && baseUrl != null) {
      final photos = json['photos'] as List<dynamic>? ?? [];
      photoUrls = photos.map((filename) {
        return '$baseUrl/api/files/creatures/${json['id']}/$filename';
      }).toList();
    }

    return CreatureData(
      id: json['id'] as String?,
      ownerId: json['owner'] as String?,
      aquariumId: json['aquarium_id'] as String,
      catalogId: json['catalog_id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      nickname: json['nickname'] as String?,
      adoptionDate: json['adoption_date'] != null
          ? DateTime.tryParse(json['adoption_date'] as String)
          : null,
      unknownAdoptionDate: json['unknown_adoption_date'] as bool? ?? false,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      gender: CreatureGender.fromValue(json['gender'] as String?),
      source: json['source'] as String?,
      price: json['price'] as String?,
      photoUrls: photoUrls,
      created: json['created'] != null
          ? DateTime.tryParse(json['created'] as String)
          : null,
      updated: json['updated'] != null
          ? DateTime.tryParse(json['updated'] as String)
          : null,
    );
  }
}
