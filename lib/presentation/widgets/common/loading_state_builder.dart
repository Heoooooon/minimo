import 'package:flutter/material.dart';
import 'empty_state.dart';

/// 로딩 상태 열거형
enum LoadingStatus { loading, success, empty, error }

/// 로딩/에러/빈 상태/성공 4가지 상태를 처리하는 빌더
///
/// 사용법:
/// ```dart
/// LoadingStateBuilder(
///   status: _isLoading ? LoadingStatus.loading : LoadingStatus.success,
///   loadingBuilder: () => SkeletonLoader(...),
///   builder: () => YourContent(),
/// )
/// ```
class LoadingStateBuilder extends StatelessWidget {
  const LoadingStateBuilder({
    super.key,
    required this.status,
    required this.builder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorMessage,
    this.onRetry,
  });

  final LoadingStatus status;

  /// 성공 상태 빌더
  final Widget Function() builder;

  /// 로딩 상태 빌더 (기본: CircularProgressIndicator)
  final Widget Function()? loadingBuilder;

  /// 빈 상태 빌더 (기본: EmptyState)
  final Widget Function()? emptyBuilder;

  /// 에러 상태 빌더 (기본: EmptyStatePresets.error)
  final Widget Function()? errorBuilder;

  /// 에러 메시지 (기본 에러 빌더에 사용)
  final String? errorMessage;

  /// 재시도 콜백 (기본 에러/빈 상태 빌더에 사용)
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadingStatus.loading:
        return loadingBuilder?.call() ??
            const Center(child: CircularProgressIndicator());
      case LoadingStatus.error:
        return errorBuilder?.call() ??
            EmptyStatePresets.error(
              message: errorMessage,
              onRetry: onRetry,
            );
      case LoadingStatus.empty:
        return emptyBuilder?.call() ??
            const EmptyState(
              icon: Icons.inbox_outlined,
              message: '데이터가 없습니다',
            );
      case LoadingStatus.success:
        return builder();
    }
  }
}
