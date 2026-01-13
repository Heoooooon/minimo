import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/aquarium_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../viewmodels/aquarium_list_viewmodel.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/aquarium/aquarium_card.dart';

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
            backgroundColor: const Color(0xFFF9FAFC),
            body: Stack(
              children: [
                _buildBody(viewModel),
                _buildTopTitleBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 상단 타이틀 바
  Widget _buildTopTitleBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9FAFC),
              Color(0x00F9FAFC),
            ],
            stops: [0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    // 왼쪽 빈 버튼 (균형용)
                    const SizedBox(width: 40, height: 40),
                    // 타이틀
                    Expanded(
                      child: Center(
                        child: Text(
                          '어항',
                          style: const TextStyle(
                            fontFamily: 'WantedSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212529),
                            height: 26 / 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    // 우측 + 버튼
                    GestureDetector(
                      onTap: _navigateToRegister,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/icon_plus.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF212529),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  /// Empty State UI - Figma 디자인 기반 (반응형)
  Widget _buildEmptyState(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // 배경 어항 아이콘 (회전, 30% 투명도) - 반응형 위치
        Positioned(
          left: screenWidth * 0.15,
          bottom: screenHeight * 0.08,
          child: Transform.rotate(
            angle: -30.965 * (3.14159265359 / 180), // 329도 회전
            child: Opacity(
              opacity: 0.3,
              child: SvgPicture.asset(
                'assets/icons/icon_aquarium.svg',
                width: screenWidth * 0.6,
                height: screenWidth * 0.6,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFE8EBF0),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),

        // 메인 콘텐츠
        SafeArea(
          child: Column(
            children: [
              // 상단 타이틀 바 영역 (120px)
              const SizedBox(height: 120),

              // 콘텐츠 영역 - 가운데 정렬
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 메인 타이틀
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'WantedSans',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212529),
                              height: 36 / 24,
                              letterSpacing: -0.25,
                            ),
                            children: [
                              TextSpan(text: '첫 번째 '),
                              TextSpan(
                                text: '내 어항',
                                style: TextStyle(color: Color(0xFF0165FE)),
                              ),
                              TextSpan(text: '을\n등록해 보세요!'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 서브 텍스트
                        const Text(
                          '기록하는 물생활을 시작해요',
                          style: TextStyle(
                            fontFamily: 'WantedSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666E78),
                            height: 24 / 16,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 48),

                        // CTA 버튼 - 반응형 너비
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 200,
                            maxWidth: 280,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _navigateToRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0165FE),
                                foregroundColor: const Color(0xFFF9FAFC),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 3,
                                ),
                              ),
                              child: const Text(
                                '어항 등록하기',
                                style: TextStyle(
                                  fontFamily: 'WantedSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 24 / 16,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 어항 리스트 UI - Figma 디자인 기반
  Widget _buildAquariumList(AquariumListViewModel viewModel) {
    final count = viewModel.aquariums.length;

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.only(top: 136, left: 16, right: 16, bottom: 16),
        children: [
          // 어항 개수 헤더
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF212529),
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
                children: [
                  const TextSpan(text: '총 '),
                  TextSpan(
                    text: '$count',
                    style: const TextStyle(color: Color(0xFF0165FE)),
                  ),
                  const TextSpan(text: '개의 어항이 있어요'),
                ],
              ),
            ),
          ),

          // 어항 카드 목록
          ...viewModel.aquariums.map((aquarium) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AquariumCard(
                  aquarium: aquarium,
                  onTap: () => _navigateToDetail(aquarium),
                  onLongPress: () => _showDeleteDialog(aquarium, viewModel),
                ),
              )),
        ],
      ),
    );
  }

  void _navigateToDetail(AquariumData aquarium) {
    Navigator.pushNamed(
      context,
      '/aquarium/detail',
      arguments: aquarium,
    );
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
