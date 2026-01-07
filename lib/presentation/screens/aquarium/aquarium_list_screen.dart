import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/aquarium_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../viewmodels/aquarium_list_viewmodel.dart';
import '../../widgets/common/app_button.dart';

/// 어항 목록 화면
///
/// Bottom Navigation 2번째 탭
/// Empty State: 등록된 어항이 없을 때 표시
class AquariumListScreen extends StatefulWidget {
  const AquariumListScreen({super.key});

  @override
  State<AquariumListScreen> createState() => _AquariumListScreenState();
}

class _AquariumListScreenState extends State<AquariumListScreen> {
  late AquariumListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AquariumListViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _navigateToRegister() async {
    final result = await Navigator.pushNamed(context, '/aquarium/register');
    if (result == true) {
      _viewModel.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<AquariumListViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: AppColors.backgroundSurface,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundSurface,
              elevation: 0,
              centerTitle: true,
              title: Text('어항', style: AppTextStyles.bodyMediumMedium),
              actions: [
                IconButton(
                  onPressed: _navigateToRegister,
                  icon: const Icon(Icons.add, color: AppColors.textMain),
                ),
              ],
            ),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(AquariumListViewModel viewModel) {
    if (viewModel.isLoading && viewModel.aquariums.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    if (viewModel.errorMessage != null && viewModel.aquariums.isEmpty) {
      return _buildErrorState(viewModel);
    }

    if (!viewModel.hasAquariums) {
      return _buildEmptyState(context);
    }

    return _buildAquariumList(viewModel);
  }

  /// Error State UI
  Widget _buildErrorState(AquariumListViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? '오류가 발생했습니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: '다시 시도',
              onPressed: viewModel.refresh,
              size: AppButtonSize.medium,
              variant: AppButtonVariant.outlined,
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State UI
  Widget _buildEmptyState(BuildContext context) {
    return Stack(
      children: [
        // 배경 물고기 일러스트 (우측 하단)
        Positioned(
          right: -40,
          bottom: 100,
          child: Opacity(
            opacity: 0.08,
            child: Icon(Icons.water, size: 300, color: AppColors.brand),
          ),
        ),

        // 메인 콘텐츠
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // 메인 타이틀
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textMain,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: '첫 번째 '),
                      TextSpan(
                        text: '내 어항',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: '을\n등록해 보세요!'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 서브 텍스트
                Text(
                  '기록하는 물생활을 시작해요',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),

                const Spacer(flex: 2),

                // CTA 버튼
                AppButton(
                  text: '어항 등록하기',
                  onPressed: _navigateToRegister,
                  size: AppButtonSize.large,
                  shape: AppButtonShape.square,
                  variant: AppButtonVariant.contained,
                  expanded: true,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 어항 리스트 UI
  Widget _buildAquariumList(AquariumListViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: AppColors.brand,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.aquariums.length,
        itemBuilder: (context, index) {
          final aquarium = viewModel.aquariums[index];
          return _buildAquariumCard(aquarium, viewModel);
        },
      ),
    );
  }

  Widget _buildAquariumCard(
    AquariumData aquarium,
    AquariumListViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: 어항 상세 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('어항 상세 화면 (추후 구현)'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onLongPress: () {
            _showDeleteDialog(aquarium, viewModel);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 어항 이미지
                _buildAquariumImage(aquarium),
                const SizedBox(width: 16),
                // 어항 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aquarium.name ?? '이름 없음',
                        style: AppTextStyles.bodyMediumMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTag(
                            aquarium.type?.label ?? '유형 없음',
                            aquarium.type == AquariumType.freshwater
                                ? AppColors.brand
                                : AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          if (aquarium.purpose != null)
                            _buildTag(
                              aquarium.purpose!.label,
                              AppColors.textSubtle,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(aquarium.settingDate),
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAquariumImage(AquariumData aquarium) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.chipPrimaryBg,
        borderRadius: BorderRadius.circular(12),
        image: aquarium.photoUrl != null
            ? DecorationImage(
                image: NetworkImage(aquarium.photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: aquarium.photoUrl == null
          ? const Icon(Icons.water, color: AppColors.brand, size: 32)
          : null,
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.captionMedium.copyWith(color: color),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} 세팅';
  }

  void _showDeleteDialog(
    AquariumData aquarium,
    AquariumListViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('어항 삭제'),
        content: Text('${aquarium.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (aquarium.id != null) {
                final success = await viewModel.deleteAquarium(aquarium.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('어항이 삭제되었습니다.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
