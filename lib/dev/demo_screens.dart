// 개발/테스트용 데모 화면들
// Demo screens - 프로덕션 빌드에서는 사용하지 않습니다.
// 디자인 시스템 테스트 및 UT 시나리오 확인용입니다.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../presentation/widgets/common/app_button.dart';
import '../presentation/widgets/common/app_chip.dart';

/// 데모 홈 화면 (UT 시나리오용)
class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('우물'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.pushNamed(context, '/design-system'),
            tooltip: '디자인 시스템',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환영 메시지
              Text('안녕하세요! 👋', style: AppTextStyles.displaySmall),
              const SizedBox(height: 8),
              Text(
                '오늘도 물고기들은 건강한가요?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 32),

              // 빠른 액션 카드들
              Text('UT 시나리오', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),

              // 어항 등록 카드
              _buildActionCard(
                context,
                icon: Icons.add_box_outlined,
                title: '어항 등록',
                description: 'Large Square Button + Radio Button 사용',
                route: '/tank-register',
              ),
              const SizedBox(height: 12),

              // 기록하기 카드
              _buildActionCard(
                context,
                icon: Icons.edit_note,
                title: '기록하기',
                description: 'Chips + Switch + Medium Round Button 사용',
                route: '/record',
              ),
              const SizedBox(height: 12),

              // 커뮤니티 질문 카드
              _buildActionCard(
                context,
                icon: Icons.help_outline,
                title: '커뮤니티 질문',
                description: 'Small Button ("내 기록 첨부") 사용',
                route: '/community-question',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String route,
  }) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.chipPrimaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.brand, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyMediumMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSubtle),
            ],
          ),
        ),
      ),
    );
  }
}

/// 디자인 시스템 미리보기 화면
class DesignSystemScreen extends StatefulWidget {
  const DesignSystemScreen({super.key});

  @override
  State<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends State<DesignSystemScreen> {
  bool _checkboxValue = false;
  bool _switchValue = false;
  int? _radioValue = 1;
  final Set<int> _selectedChips = {0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('디자인 시스템')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 버튼 섹션
              _buildSectionTitle('Buttons'),
              const SizedBox(height: 16),
              _buildButtonSection(),
              const SizedBox(height: 32),

              // 칩 섹션
              _buildSectionTitle('Chips'),
              const SizedBox(height: 16),
              _buildChipSection(),
              const SizedBox(height: 32),

              // 컨트롤 섹션
              _buildSectionTitle('Controls'),
              const SizedBox(height: 16),
              _buildControlSection(),
              const SizedBox(height: 32),

              // 타이포그래피 섹션
              _buildSectionTitle('Typography'),
              const SizedBox(height: 16),
              _buildTypographySection(),
              const SizedBox(height: 32),

              // 컬러 섹션
              _buildSectionTitle('Colors'),
              const SizedBox(height: 16),
              _buildColorSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.headlineMedium);
  }

  Widget _buildButtonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large Buttons
        Text('Large (56px)', style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Square',
                onPressed: () {},
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                text: 'Round',
                onPressed: () {},
                size: AppButtonSize.large,
                shape: AppButtonShape.round,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Medium Buttons
        Text('Medium (40px)', style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            AppButton(
              text: 'Contained',
              onPressed: () {},
              size: AppButtonSize.medium,
            ),
            const SizedBox(width: 8),
            AppButton(
              text: 'Outlined',
              onPressed: () {},
              size: AppButtonSize.medium,
              variant: AppButtonVariant.outlined,
            ),
            const SizedBox(width: 8),
            AppButton(
              text: 'Text',
              onPressed: () {},
              size: AppButtonSize.medium,
              variant: AppButtonVariant.text,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Small Buttons
        Text('Small (32px)', style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            AppButton(
              text: '내 기록 첨부',
              onPressed: () {},
              size: AppButtonSize.small,
              variant: AppButtonVariant.outlined,
              leadingIcon: Icons.attach_file,
            ),
            const SizedBox(width: 8),
            AppButton(
              text: 'Disabled',
              onPressed: null,
              size: AppButtonSize.small,
              isEnabled: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip Types
        Text('Chip Types', style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            AppChip(label: 'Primary', type: AppChipType.primary),
            AppChip(label: 'Secondary', type: AppChipType.secondary),
            AppChip(label: 'Success', type: AppChipType.success),
            AppChip(label: 'Error', type: AppChipType.error),
            AppChip(label: 'Neutral', type: AppChipType.neutral),
            AppChip(label: 'Disabled', isEnabled: false),
          ],
        ),
        const SizedBox(height: 16),

        // Selectable Chips
        Text('Selectable Chips', style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        AppChipGroup(
          labels: const ['물갈이', '청소', '먹이주기', '수질검사'],
          selectedIndices: _selectedChips,
          onSelectionChanged: (indices) {
            setState(() {
              _selectedChips
                ..clear()
                ..addAll(indices);
            });
          },
        ),
      ],
    );
  }

  Widget _buildControlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox
        Row(
          children: [
            Checkbox(
              value: _checkboxValue,
              onChanged: (v) => setState(() => _checkboxValue = v!),
            ),
            Text('Checkbox', style: AppTextStyles.bodyMedium),
            const SizedBox(width: 16),
            Checkbox(value: true, onChanged: null),
            Text('Disabled', style: AppTextStyles.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),

        // Radio
        Row(
          children: [
            Radio<int>(
              value: 1,
              groupValue: _radioValue,
              onChanged: (v) => setState(() => _radioValue = v),
            ),
            Text('Option 1', style: AppTextStyles.bodyMedium),
            Radio<int>(
              value: 2,
              groupValue: _radioValue,
              onChanged: (v) => setState(() => _radioValue = v),
            ),
            Text('Option 2', style: AppTextStyles.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),

        // Switch
        Row(
          children: [
            Switch(
              value: _switchValue,
              onChanged: (v) => setState(() => _switchValue = v),
            ),
            Text('Switch', style: AppTextStyles.bodyMedium),
            const SizedBox(width: 16),
            Switch(value: false, onChanged: null),
            Text('Disabled', style: AppTextStyles.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildTypographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large (32px Bold)', style: AppTextStyles.displayLarge),
        Text(
          'Headline Medium (20px SemiBold)',
          style: AppTextStyles.headlineMedium,
        ),
        Text('Title Medium (16px Medium)', style: AppTextStyles.titleMedium),
        Text('Body Medium (16px Regular)', style: AppTextStyles.bodyMedium),
        Text(
          'Caption Medium (12px Medium)',
          style: AppTextStyles.captionMedium,
        ),
        Text('Label Small (11px Medium)', style: AppTextStyles.labelSmall),
      ],
    );
  }

  Widget _buildColorSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildColorChip('Brand', AppColors.brand),
        _buildColorChip('Secondary', AppColors.secondary),
        _buildColorChip('Success', AppColors.success),
        _buildColorChip('Error', AppColors.error),
        _buildColorChip('Text Main', AppColors.textMain),
        _buildColorChip('Border', AppColors.border),
        _buildColorChip('Background', AppColors.backgroundApp),
        _buildColorChip('Disabled', AppColors.disabled),
      ],
    );
  }

  Widget _buildColorChip(String name, Color color) {
    final bool isLight = color.computeLuminance() > 0.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        style: AppTextStyles.captionMedium.copyWith(
          color: isLight ? AppColors.textMain : AppColors.textInverse,
        ),
      ),
    );
  }
}
