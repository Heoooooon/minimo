class CreatureCatalogData {
  CreatureCatalogData({
    this.id,
    required this.category,
    required this.name,
    required this.normalizedKey,
    this.imageUrl,
    this.imageFile,
    required this.createdBy,
    required this.status,
    required this.reportCount,
    this.created,
    this.updated,
  });

  /// PocketBase record ID
  final String? id;

  /// 대분류 (예: "구피")
  final String category;

  /// 하위 이름/품종 (예: "알비노 풀레드")
  final String name;

  /// 정규화된 고유 키 (예: "구피/알비노풀레드")
  final String normalizedKey;

  /// 대표 이미지 URL (서버)
  final String? imageUrl;

  /// 대표 이미지 파일 경로 (로컬, 업로드 전)
  final String? imageFile;

  /// 생성자(유저) ID
  final String createdBy;

  /// 공개 상태
  final String status; // public | hidden

  /// 신고 수
  final int reportCount;

  /// 생성일시
  final DateTime? created;

  /// 수정일시
  final DateTime? updated;

  String get displayPath => '$name/$category';

  CreatureCatalogData copyWith({
    String? id,
    String? category,
    String? name,
    String? normalizedKey,
    String? imageUrl,
    String? imageFile,
    String? createdBy,
    String? status,
    int? reportCount,
    DateTime? created,
    DateTime? updated,
  }) {
    return CreatureCatalogData(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      normalizedKey: normalizedKey ?? this.normalizedKey,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFile: imageFile ?? this.imageFile,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      reportCount: reportCount ?? this.reportCount,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'name': name,
      'normalized_key': normalizedKey,
      'created_by': createdBy,
      'status': status,
      'report_count': reportCount,
    };
  }

  factory CreatureCatalogData.fromJson(
    Map<String, dynamic> json, {
    String? baseUrl,
  }) {
    String? imageUrl;
    if (json['image'] != null && json['id'] != null && baseUrl != null) {
      imageUrl =
          '$baseUrl/api/files/creature_catalog/${json['id']}/${json['image']}';
    }

    return CreatureCatalogData(
      id: json['id'] as String?,
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      normalizedKey: json['normalized_key'] as String? ?? '',
      imageUrl: imageUrl,
      createdBy: json['created_by'] as String? ?? '',
      status: json['status'] as String? ?? 'public',
      reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
      created: json['created'] != null
          ? DateTime.tryParse(json['created'] as String)
          : null,
      updated: json['updated'] != null
          ? DateTime.tryParse(json['updated'] as String)
          : null,
    );
  }
}
