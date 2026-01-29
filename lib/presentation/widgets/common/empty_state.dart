import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'app_button.dart';

/// 빈 상태 화면 위젯
///
/// 데이터가 없을 때 표시하는 통일된 UI 컴포넌트
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.icon,
    this.svgAsset,
    this.iconSize = 80,
    this.actionLabel,
    this.onAction,
  });

  /// 메인 메시지
  final String message;

  /// 서브 메시지 (선택)
  final String? subMessage;

  /// 아이콘 (IconData)
  final IconData? icon;

  /// SVG 에셋 경로 (아이콘 대신 사용)
  final String? svgAsset;

  /// 아이콘 크기
  final double iconSize;

  /// 액션 버튼 라벨 (선택)
  final String? actionLabel;

  /// 액션 버튼 콜백 (선택)
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 또는 SVG
            _buildIcon(),
            const SizedBox(height: 24),

            // 메인 메시지
            Text(
              message,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textMain,
              ),
              textAlign: TextAlign.center,
            ),

            // 서브 메시지
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 액션 버튼
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: actionLabel!,
                onPressed: onAction,
                size: AppButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (svgAsset != null) {
      return SvgPicture.asset(
        svgAsset!,
        width: iconSize,
        height: iconSize,
        colorFilter: const ColorFilter.mode(
          AppColors.textHint,
          BlendMode.srcIn,
        ),
      );
    }

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.inbox_outlined,
        size: iconSize * 0.5,
        color: AppColors.textHint,
      ),
    );
  }
}

/// 미리 정의된 빈 상태 타입
class EmptyStatePresets {
  EmptyStatePresets._();

  /// 게시글 없음
  static EmptyState noPosts({VoidCallback? onAction}) => EmptyState(
    icon: Icons.article_outlined,
    message: '아직 게시글이 없습니다',
    subMessage: '첫 번째 게시글을 작성해보세요!',
    actionLabel: onAction != null ? '글쓰기' : null,
    onAction: onAction,
  );

  /// 질문 없음
  static EmptyState noQuestions({VoidCallback? onAction}) => EmptyState(
    icon: Icons.help_outline,
    message: '아직 질문이 없습니다',
    subMessage: '궁금한 점을 질문해보세요!',
    actionLabel: onAction != null ? '질문하기' : null,
    onAction: onAction,
  );

  /// 댓글/답변 없음
  static EmptyState noComments({String type = '댓글'}) => EmptyState(
    icon: Icons.chat_bubble_outline,
    message: '아직 $type이 없습니다',
    subMessage: '첫 번째 $type을 작성해보세요!',
  );

  /// 검색 결과 없음
  static EmptyState noSearchResults({String? query}) => EmptyState(
    icon: Icons.search_off,
    message: '검색 결과가 없습니다',
    subMessage: query != null ? '"$query"에 대한 결과를 찾을 수 없습니다' : null,
  );

  /// 알림 없음
  static const EmptyState noNotifications = EmptyState(
    icon: Icons.notifications_none,
    message: '알림이 없습니다',
    subMessage: '새로운 소식이 오면 알려드릴게요',
  );

  /// 어항 없음
  static EmptyState noAquariums({VoidCallback? onAction}) => EmptyState(
    icon: Icons.waves_outlined,
    message: '등록된 어항이 없습니다',
    subMessage: '첫 번째 어항을 등록해보세요!',
    actionLabel: onAction != null ? '어항 등록하기' : null,
    onAction: onAction,
  );

  /// 생물 없음
  static EmptyState noCreatures({VoidCallback? onAction}) => EmptyState(
    icon: Icons.pets_outlined,
    message: '등록된 생물이 없습니다',
    subMessage: '어항에 생물을 추가해보세요!',
    actionLabel: onAction != null ? '생물 추가하기' : null,
    onAction: onAction,
  );

  /// 일정 없음
  static EmptyState noSchedules({VoidCallback? onAction}) => EmptyState(
    icon: Icons.event_available_outlined,
    message: '등록된 알림이 없습니다',
    subMessage: '관리 일정을 등록해보세요!',
    actionLabel: onAction != null ? '알림 추가하기' : null,
    onAction: onAction,
  );

  /// 사진 없음
  static EmptyState noPhotos({VoidCallback? onAction}) => EmptyState(
    icon: Icons.photo_library_outlined,
    message: '등록된 사진이 없습니다',
    subMessage: '어항의 모습을 기록해보세요!',
    actionLabel: onAction != null ? '사진 추가하기' : null,
    onAction: onAction,
  );

  /// 팔로잉 게시글 없음
  static const EmptyState noFollowingPosts = EmptyState(
    icon: Icons.people_outline,
    message: '팔로우한 사용자의 게시글이 없습니다',
    subMessage: '관심있는 사용자를 팔로우해보세요!',
  );

  /// 메모 없음
  static EmptyState noMemos({VoidCallback? onAction}) => EmptyState(
    icon: Icons.note_outlined,
    message: '등록된 메모가 없습니다',
    subMessage: '관찰 기록을 남겨보세요!',
    actionLabel: onAction != null ? '메모 추가하기' : null,
    onAction: onAction,
  );

  /// 네트워크 에러
  static EmptyState networkError({VoidCallback? onRetry}) => EmptyState(
    icon: Icons.wifi_off_outlined,
    message: '연결할 수 없습니다',
    subMessage: '네트워크 연결을 확인해주세요',
    actionLabel: onRetry != null ? '다시 시도' : null,
    onAction: onRetry,
  );

  /// 일반 에러
  static EmptyState error({String? message, VoidCallback? onRetry}) =>
      EmptyState(
        icon: Icons.error_outline,
        message: message ?? '오류가 발생했습니다',
        subMessage: '잠시 후 다시 시도해주세요',
        actionLabel: onRetry != null ? '다시 시도' : null,
        onAction: onRetry,
      );
}
