import 'package:flutter/material.dart';

/// 커스텀 페이지 전환 애니메이션
class PageTransitions {
  PageTransitions._();

  /// 기본 전환 시간
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration fastDuration = Duration(milliseconds: 200);

  /// iOS 스타일 슬라이드 전환 (오른쪽에서 왼쪽)
  static Route<T> slideRight<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? defaultDuration,
      reverseTransitionDuration: duration ?? defaultDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// 아래에서 위로 슬라이드 (모달 스타일)
  static Route<T> slideUp<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
    bool opaque = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: opaque,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? defaultDuration,
      reverseTransitionDuration: duration ?? fastDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// 페이드 전환
  static Route<T> fade<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? fastDuration,
      reverseTransitionDuration: duration ?? fastDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  /// 페이드 + 스케일 전환 (줌 인)
  static Route<T> fadeScale<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? defaultDuration,
      reverseTransitionDuration: duration ?? fastDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// 공유 요소 전환 (Hero와 함께 사용)
  static Route<T> sharedAxis<T>({
    required Widget page,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? defaultDuration,
      reverseTransitionDuration: duration ?? defaultDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        // 들어오는 페이지는 페이드 + 슬라이드
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }
}

/// Navigator 확장 메서드
extension NavigatorExtensions on NavigatorState {
  /// 슬라이드 전환으로 페이지 이동
  Future<T?> pushSlide<T>(Widget page, {RouteSettings? settings}) {
    return push(PageTransitions.slideRight<T>(page: page, settings: settings));
  }

  /// 모달 스타일로 페이지 이동 (아래에서 위로)
  Future<T?> pushModal<T>(Widget page, {RouteSettings? settings}) {
    return push(PageTransitions.slideUp<T>(page: page, settings: settings));
  }

  /// 페이드 전환으로 페이지 이동
  Future<T?> pushFade<T>(Widget page, {RouteSettings? settings}) {
    return push(PageTransitions.fade<T>(page: page, settings: settings));
  }

  /// 기존 스택 교체하면서 슬라이드 전환
  Future<T?> pushReplacementSlide<T, TO>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return pushReplacement(
      PageTransitions.slideRight<T>(page: page, settings: settings),
    );
  }

  /// 모든 스택 제거하고 새 페이지로 (페이드)
  Future<T?> pushAndRemoveAllFade<T>(Widget page, {RouteSettings? settings}) {
    return pushAndRemoveUntil(
      PageTransitions.fade<T>(page: page, settings: settings),
      (route) => false,
    );
  }
}

/// BuildContext 확장 메서드 (더 편리한 사용)
extension ContextNavigatorExtensions on BuildContext {
  /// 슬라이드 전환으로 페이지 이동
  Future<T?> pushSlide<T>(Widget page, {RouteSettings? settings}) {
    return Navigator.of(this).pushSlide<T>(page, settings: settings);
  }

  /// 모달 스타일로 페이지 이동
  Future<T?> pushModal<T>(Widget page, {RouteSettings? settings}) {
    return Navigator.of(this).pushModal<T>(page, settings: settings);
  }

  /// 페이드 전환으로 페이지 이동
  Future<T?> pushFade<T>(Widget page, {RouteSettings? settings}) {
    return Navigator.of(this).pushFade<T>(page, settings: settings);
  }
}
