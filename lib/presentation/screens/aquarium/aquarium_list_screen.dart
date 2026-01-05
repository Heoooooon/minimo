import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';

/// 어항 목록 화면
///
/// Bottom Navigation 2번째 탭
/// Empty State: 등록된 어항이 없을 때 표시
class AquariumListScreen extends StatelessWidget {
  const AquariumListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 데이터 연동 시 aquariums 리스트로 변경
    final bool isEmpty = true;

    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        centerTitle: true,
        title: Text('어항', style: AppTextStyles.bodyMediumMedium),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/aquarium/register');
            },
            icon: const Icon(Icons.add, color: AppColors.textMain),
          ),
        ],
      ),
      body: isEmpty ? _buildEmptyState(context) : _buildAquariumList(),
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
                  onPressed: () {
                    Navigator.pushNamed(context, '/aquarium/register');
                  },
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

  /// 어항 리스트 UI (추후 구현)
  Widget _buildAquariumList() {
    return const Center(child: Text('어항 리스트'));
  }
}
