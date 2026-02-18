import 'package:flutter/material.dart';

/// 앱 간격 시스템
///
/// 모든 화면에서 일관된 간격을 위한 상수
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  /// 화면 좌우 기본 패딩
  static const double screenHorizontal = 16.0;

  /// 섹션 간 간격
  static const double sectionGap = 24.0;

  /// 카드 내부 패딩
  static const double cardPadding = 16.0;
}

/// 앱 모서리 반지름 시스템
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;

  static const BorderRadius xsBorderRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smBorderRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorderRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorderRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorderRadius = BorderRadius.all(Radius.circular(xl));
}

/// 앱 그림자 시스템
class AppShadow {
  AppShadow._();

  /// 카드 기본 그림자
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D846EFF),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];

  /// 강조된 그림자 (FAB, 모달 등)
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1A846EFF),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  /// 미세한 그림자 (호버 상태)
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
