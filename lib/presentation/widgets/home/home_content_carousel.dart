import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'community_card.dart';

/// 홈 화면 추천 콘텐츠 캐러셀
///
/// 커뮤니티 카드를 페이지 형태로 스와이프하며 볼 수 있는 캐러셀
class HomeContentCarousel extends StatefulWidget {
  const HomeContentCarousel({super.key, required this.items, this.onItemTap});

  /// 커뮤니티 아이템 리스트
  final List<CommunityData> items;

  /// 아이템 탭 콜백
  final void Function(CommunityData)? onItemTap;

  @override
  State<HomeContentCarousel> createState() => _HomeContentCarouselState();
}

class _HomeContentCarouselState extends State<HomeContentCarousel> {
  int _currentPageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 16 : 6, right: 6),
                child: CommunityCard(
                  data: widget.items[index],
                  onTap: () => widget.onItemTap?.call(widget.items[index]),
                  isActive: index == _currentPageIndex,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Pagination Dots
        _buildPaginationDots(),
      ],
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.items.length, (index) {
        final isActive = index == _currentPageIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: AppRadius.xsBorderRadius,
            color: isActive ? AppColors.brand : AppColors.borderLight,
          ),
        );
      }),
    );
  }
}
