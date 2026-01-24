enum AquariumType {
  freshwater('담수'),
  saltwater('해수');

  const AquariumType(this.label);
  final String label;

  String get value => name;

  static AquariumType? fromValue(String? value) {
    if (value == null) return null;
    return AquariumType.values.where((e) => e.name == value).firstOrNull;
  }
}

enum FilterType {
  hangOn('걸이식'),
  canister('외부 여과기'),
  sponge('스펀지 여과기'),
  internal('내부 여과기'),
  sump('섬프'),
  none('없음');

  const FilterType(this.label);
  final String label;

  String get value {
    switch (this) {
      case FilterType.hangOn:
        return 'hang_on';
      case FilterType.canister:
        return 'canister';
      case FilterType.sponge:
        return 'sponge';
      case FilterType.internal:
        return 'internal';
      case FilterType.sump:
        return 'sump';
      case FilterType.none:
        return 'none';
    }
  }

  static FilterType? fromValue(String? value) {
    if (value == null) return null;
    return FilterType.values.where((e) => e.value == value).firstOrNull;
  }
}

enum LightingType {
  led('LED'),
  fluorescent('형광등'),
  metalHalide('메탈할라이드'),
  none('없음');

  const LightingType(this.label);
  final String label;

  String get value {
    switch (this) {
      case LightingType.led:
        return 'led';
      case LightingType.fluorescent:
        return 'fluorescent';
      case LightingType.metalHalide:
        return 'metal_halide';
      case LightingType.none:
        return 'none';
    }
  }

  static LightingType? fromValue(String? value) {
    if (value == null) return null;
    return LightingType.values.where((e) => e.value == value).firstOrNull;
  }
}

enum AquariumPurpose {
  general('일반 사육'),
  breeding('브리딩'),
  aquascape('수초'),
  neglect('방치'),
  fry('치어');

  const AquariumPurpose(this.label);
  final String label;

  String get value => name;

  static AquariumPurpose? fromValue(String? value) {
    if (value == null) return null;
    return AquariumPurpose.values.where((e) => e.name == value).firstOrNull;
  }
}

class AquariumData {
  AquariumData({
    this.id,
    this.ownerId,
    this.name,
    this.type,
    this.settingDate,
    this.dimensions,
    this.filterType,
    this.substrate,
    this.productName,
    this.lighting,
    this.hasHeater,
    this.purpose,
    this.notes,
    this.photoPath,
    this.photoUrl,
  });

  String? id;
  String? ownerId;
  String? name;
  AquariumType? type;
  DateTime? settingDate;
  String? dimensions;
  FilterType? filterType;
  String? substrate;
  String? productName;
  LightingType? lighting;
  bool? hasHeater;
  AquariumPurpose? purpose;
  String? notes;
  String? photoPath;
  String? photoUrl;

  bool get isStep1Valid =>
      name != null &&
      name!.isNotEmpty &&
      type != null &&
      settingDate != null &&
      dimensions != null &&
      dimensions!.isNotEmpty;

  bool get isStep2Valid => true;

  bool get isStep3Valid => true;

  bool get isStep4Valid => true;

  bool get isAllValid => isStep1Valid;

  AquariumData copyWith({
    String? id,
    String? ownerId,
    String? name,
    AquariumType? type,
    DateTime? settingDate,
    String? dimensions,
    FilterType? filterType,
    String? substrate,
    String? productName,
    LightingType? lighting,
    bool? hasHeater,
    AquariumPurpose? purpose,
    String? notes,
    String? photoPath,
    String? photoUrl,
  }) {
    return AquariumData(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      settingDate: settingDate ?? this.settingDate,
      dimensions: dimensions ?? this.dimensions,
      filterType: filterType ?? this.filterType,
      substrate: substrate ?? this.substrate,
      productName: productName ?? this.productName,
      lighting: lighting ?? this.lighting,
      hasHeater: hasHeater ?? this.hasHeater,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type?.value,
      'setting_date': settingDate?.toIso8601String(),
      'dimensions': dimensions,
      'filter_type': filterType?.value,
      'substrate': substrate,
      'product_name': productName,
      'lighting': lighting?.value,
      'heater': hasHeater,
      'purpose': purpose?.value,
      'notes': notes,
    };
  }

  factory AquariumData.fromJson(Map<String, dynamic> json) {
    return AquariumData(
      id: json['id'] as String?,
      ownerId: json['owner'] as String?,
      name: json['name'] as String?,
      type: AquariumType.fromValue(json['type'] as String?),
      settingDate: json['setting_date'] != null
          ? DateTime.tryParse(json['setting_date'] as String)
          : null,
      dimensions: json['dimensions'] as String?,
      filterType: FilterType.fromValue(json['filter_type'] as String?),
      substrate: json['substrate'] as String?,
      productName: json['product_name'] as String?,
      lighting: LightingType.fromValue(json['lighting'] as String?),
      hasHeater: json['heater'] as bool?,
      purpose: AquariumPurpose.fromValue(json['purpose'] as String?),
      notes: json['notes'] as String?,
      photoUrl: json['photo'] as String?,
    );
  }
}
