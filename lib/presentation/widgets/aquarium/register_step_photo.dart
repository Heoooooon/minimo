import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 어항 등록 Step 4: 대표 사진 등록
///
/// 어항의 대표 사진을 등록하는 화면
class RegisterStepPhoto extends StatelessWidget {
  const RegisterStepPhoto({
    super.key,
    required this.photoPath,
    this.photoBytes,
    required this.isLoading,
    required this.onPickFromGallery,
    required this.onTakePhoto,
    required this.onRemovePhoto,
  });

  /// 선택된 사진 경로 (네이티브 플랫폼용)
  final String? photoPath;

  /// 선택된 사진 bytes (웹 플랫폼용)
  final Uint8List? photoBytes;

  /// 로딩 상태
  final bool isLoading;

  /// 갤러리에서 선택 콜백
  final VoidCallback onPickFromGallery;

  /// 카메라로 촬영 콜백
  final VoidCallback onTakePhoto;

  /// 사진 제거 콜백
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Text(
            '대표 사진을\n등록해 주세요.',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '어항 목록에서 보여질 대표 사진이에요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 40),

          // 사진 영역
          Center(
            child: photoPath != null
                ? _buildPhotoPreview(context)
                : _buildPhotoPlaceholder(context),
          ),

          const SizedBox(height: 32),

          // 사진 선택 버튼들
          if (photoPath == null) ...[
            _buildActionButton(
              context,
              icon: Icons.photo_library_outlined,
              label: '갤러리에서 선택',
              onTap: onPickFromGallery,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.camera_alt_outlined,
              label: '카메라로 촬영',
              onTap: onTakePhoto,
            ),
          ] else ...[
            _buildActionButton(
              context,
              icon: Icons.refresh,
              label: '다른 사진으로 변경',
              onTap: onPickFromGallery,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: onPickFromGallery,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.backgroundApp,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.borderLight,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brand,
                  strokeWidth: 3,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.chipPrimaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.brand,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '사진 추가',
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPhotoPreview(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brand, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: isLoading
                ? Container(
                    color: AppColors.backgroundApp,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brand,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : _buildImage(),
          ),
        ),
        // 삭제 버튼
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemovePhoto,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.textSubtle,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 플랫폼에 맞는 이미지 위젯 빌드
  Widget _buildImage() {
    // 웹 플랫폼이거나 bytes가 있는 경우 Image.memory 사용
    if (kIsWeb && photoBytes != null) {
      return Image.memory(
        photoBytes!,
        fit: BoxFit.cover,
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError();
        },
      );
    }

    // 네이티브 플랫폼에서는 Image.file 사용
    if (!kIsWeb && photoPath != null) {
      return Image.file(
        File(photoPath!),
        fit: BoxFit.cover,
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError();
        },
      );
    }

    // 폴백: bytes가 있으면 사용
    if (photoBytes != null) {
      return Image.memory(
        photoBytes!,
        fit: BoxFit.cover,
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError();
        },
      );
    }

    return _buildImageError();
  }

  Widget _buildImageError() {
    return Container(
      color: AppColors.backgroundApp,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textHint,
        size: 48,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.chipPrimaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.brand, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMediumBold.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
