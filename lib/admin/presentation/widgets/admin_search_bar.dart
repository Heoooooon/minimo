import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 관리자 패널 검색바 위젯
///
/// 텍스트 검색과 드롭다운 필터를 제공하는 재사용 가능한 검색 컴포넌트
class AdminSearchBar extends StatefulWidget {
  const AdminSearchBar({
    super.key,
    this.hintText = '검색...',
    this.onSearch,
    this.filterOptions,
    this.selectedFilter,
    this.onFilterChanged,
  });

  final String hintText;
  final ValueChanged<String>? onSearch;
  final List<AdminFilterOption>? filterOptions;
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterChanged;

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 검색 텍스트 필드
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearch?.call('');
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 10,
              ),
              border: const OutlineInputBorder(
                borderRadius: AppRadius.smBorderRadius,
              ),
            ),
            onChanged: (value) => setState(() {}),
            onSubmitted: widget.onSearch,
          ),
        ),
        // 필터 드롭다운 (옵션이 있을 때만 표시)
        if (widget.filterOptions != null &&
            widget.filterOptions!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
              borderRadius: AppRadius.smBorderRadius,
              color: AppColors.backgroundSurface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.selectedFilter,
                hint: const Text('필터', style: TextStyle(fontSize: 14)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('전체')),
                  ...widget.filterOptions!.map(
                    (option) => DropdownMenuItem(
                      value: option.value,
                      child: Text(
                        option.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
                onChanged: widget.onFilterChanged,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 필터 드롭다운 옵션 데이터 클래스
class AdminFilterOption {
  const AdminFilterOption({required this.label, required this.value});

  final String label;
  final String value;
}
