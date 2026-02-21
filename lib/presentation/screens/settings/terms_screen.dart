import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 이용 약관 화면
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('이용 약관', style: AppTextStyles.bodyMediumBold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            '서비스 이용 약관',
            '우물(Oomool) 서비스를 이용해 주셔서 감사합니다.\n'
                '본 약관은 우물 서비스의 이용에 관한 기본적인 사항을 규정합니다.',
          ),
          _buildSection(
            '개인정보 처리방침',
            '우물은 사용자의 개인정보를 소중히 여기며, '
                '관련 법령에 따라 개인정보를 보호하고 있습니다.\n\n'
                '수집하는 개인정보:\n'
                '• 이메일 주소 (회원가입 및 로그인)\n'
                '• 닉네임 (서비스 이용)\n'
                '• 어항 관리 데이터 (서비스 제공)',
          ),
          _buildSection(
            '데이터 보관 및 삭제',
            '사용자가 입력한 어항 관리 데이터는 서비스 제공을 위해 보관되며, '
                '회원 탈퇴 시 모든 데이터가 삭제됩니다.\n\n'
                '데이터 백업 기능을 통해 개인 데이터를 내보낼 수 있습니다.',
          ),
          _buildSection(
            '면책 조항',
            '우물 서비스는 어항 관리 참고 정보를 제공하며, '
                '수생 생물의 건강과 관련된 전문적인 조언을 대체하지 않습니다.',
          ),
          const SizedBox(height: 24),
          Text(
            '최종 업데이트: 2025년 2월',
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMediumBold.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
