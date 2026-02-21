import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 게시글 옵션 바텀시트 표시
void showPostOptionsSheet(
  BuildContext context, {
  required bool isAuthor,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onReport,
  required VoidCallback onShare,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 작성자만 수정/삭제 가능
          if (isAuthor) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('수정하기'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              title: const Text(
                '삭제하기',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('신고하기'),
            onTap: () {
              Navigator.pop(context);
              onReport();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('공유하기'),
            onTap: () {
              Navigator.pop(context);
              onShare();
            },
          ),
        ],
      ),
    ),
  );
}

/// 게시글 수정 다이얼로그 표시
void showPostEditDialog(
  BuildContext context, {
  required String currentContent,
  required Future<void> Function(String newContent) onUpdate,
}) {
  final TextEditingController editController = TextEditingController(
    text: currentContent,
  );

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('게시글 수정'),
      content: TextField(
        controller: editController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: '내용을 입력하세요',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('취소', style: TextStyle(color: AppColors.textSubtle)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (editController.text.trim().isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('내용을 입력해주세요.'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            Navigator.pop(dialogContext);
            await onUpdate(editController.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
          child: const Text('수정', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// 게시글 삭제 확인 다이얼로그 표시
void showPostDeleteConfirmDialog(
  BuildContext context, {
  required VoidCallback onDelete,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('게시글 삭제'),
      content: const Text('정말 이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('취소', style: TextStyle(color: AppColors.textSubtle)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onDelete();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('삭제', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// 게시글 신고 다이얼로그 표시
void showPostReportDialog(
  BuildContext context, {
  required VoidCallback onReported,
}) {
  final reasons = ['스팸/광고', '욕설/비하', '음란물', '허위정보', '저작권 침해', '기타'];
  String? selectedReason;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('게시글 신고'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '신고 사유를 선택해주세요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: selectedReason ?? '',
              onChanged: (value) {
                setState(() {
                  selectedReason = value;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons
                    .map(
                      (reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소', style: TextStyle(color: AppColors.textSubtle)),
          ),
          ElevatedButton(
            onPressed: selectedReason == null
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    onReported();
                  },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('신고', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
