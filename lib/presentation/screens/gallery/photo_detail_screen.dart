import 'package:flutter/material.dart';
import '../../../domain/models/gallery_photo_data.dart';
import '../../../data/services/gallery_photo_service.dart';
import '../../../theme/app_colors.dart';

/// 갤러리 사진 상세 화면
///
/// 풀스크린 이미지 뷰어 + 핀치 줌/팬 제스처 지원
/// Path: /gallery/photo-detail
class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({super.key});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  GalleryPhotoData? _photo;
  final TransformationController _transformationController =
      TransformationController();
  bool _showInfo = true;
  bool _isDeleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is GalleryPhotoData && _photo?.id != args.id) {
      setState(() {
        _photo = args;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}';
  }

  void _toggleInfo() {
    setState(() {
      _showInfo = !_showInfo;
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && _photo?.id != null) {
      await _deletePhoto();
    }
  }

  Future<void> _deletePhoto() async {
    if (_photo?.id == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await GalleryPhotoService.instance.deletePhoto(_photo!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진이 삭제되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // true = 삭제됨
      }
    } catch (e) {
      debugPrint('Failed to delete photo: $e');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진 삭제에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photo == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            '사진을 불러올 수 없습니다',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // 이미지 뷰어 (핀치 줌/팬 지원)
          GestureDetector(
            onTap: _toggleInfo,
            onDoubleTap: _resetZoom,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                child: _photo?.imageUrl != null
                    ? Image.network(
                        _photo!.imageUrl!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF333333),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF333333),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // 하단 정보 패널
          if (_showInfo)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildInfoPanel(),
            ),

          // 삭제 중 로딩 오버레이
          if (_isDeleting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _showInfo ? Colors.black54 : Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      ),
      actions: [
        // 삭제 버튼
        IconButton(
          onPressed: _isDeleting ? null : _confirmDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black87,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 촬영일
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(_photo!.photoDate),
                style: const TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // 캡션 (있는 경우)
          if (_photo!.caption != null && _photo!.caption!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _photo!.caption!,
              style: const TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ],
          // 생물 정보 (있는 경우)
          if (_photo!.creatureName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _photo!.creatureName!,
                style: const TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
