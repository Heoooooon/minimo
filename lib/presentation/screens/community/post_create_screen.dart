import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../data/services/community_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/tag_service.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../viewmodels/community_post_viewmodel.dart';

/// 게시글 작성 화면
class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  late final AppDependencies _dependencies;
  late final CommunityService _service;
  late final TagService _tagService;
  late final AuthService _authService;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<XFile> _selectedImages = [];
  final List<String> _selectedTags = [];
  List<TagData> _popularTags = [];
  List<TagData> _searchedTags = [];
  bool _isSubmitting = false;
  bool _isLoadingTags = false;
  bool _showTagSearch = false;
  bool _isDependenciesReady = false;
  static const int _maxImages = 5;
  static const int _maxTags = 5;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    _dependencies = context.read<AppDependencies>();
    _service = _dependencies.communityService;
    _tagService = _dependencies.tagService;
    _authService = _dependencies.authService;
    _isDependenciesReady = true;

    _loadPopularTags();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularTags() async {
    setState(() => _isLoadingTags = true);
    try {
      final tags = await _tagService.getPopularTags(limit: 10);
      setState(() {
        _popularTags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      AppLogger.data('인기 태그 로드 실패: $e', isError: true);
      setState(() => _isLoadingTags = false);
    }
  }

  Future<void> _searchTags(String query) async {
    if (query.isEmpty) {
      setState(() => _searchedTags = []);
      return;
    }

    try {
      final tags = await _tagService.searchTags(query: query, limit: 10);
      setState(() => _searchedTags = tags);
    } catch (e) {
      AppLogger.data('태그 검색 실패: $e', isError: true);
    }
  }

  void _addTag(String tagName) {
    final cleanTag = tagName.replaceAll('#', '').trim();
    if (cleanTag.isEmpty) return;
    if (_selectedTags.length >= _maxTags) {
      _showSnackBar('최대 $_maxTags개의 태그만 추가할 수 있습니다.');
      return;
    }
    if (_selectedTags.contains(cleanTag)) {
      _showSnackBar('이미 추가된 태그입니다.');
      return;
    }

    setState(() {
      _selectedTags.add(cleanTag);
      _tagController.clear();
      _searchedTags = [];
      _showTagSearch = false;
    });
  }

  void _removeTag(String tagName) {
    setState(() {
      _selectedTags.remove(tagName);
    });
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      _showSnackBar('최대 $_maxImages장까지 첨부할 수 있습니다.');
      return;
    }

    final remainingSlots = _maxImages - _selectedImages.length;

    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.take(remainingSlots));
        });

        if (images.length > remainingSlots) {
          _showSnackBar('최대 $_maxImages장까지 첨부할 수 있습니다.');
        }
      }
    } catch (e) {
      AppLogger.error('[UI] 이미지 선택 실패: $e');
      _showSnackBar('이미지를 불러오는데 실패했습니다.');
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= _maxImages) {
      _showSnackBar('최대 $_maxImages장까지 첨부할 수 있습니다.');
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      AppLogger.error('[UI] 카메라 사용 실패: $e');
      _showSnackBar('카메라를 사용할 수 없습니다.');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      _showSnackBar('내용을 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 현재 사용자 정보 가져오기 (없으면 익명)
      final currentUser = _authService.currentUser;
      final userId = currentUser?.id ?? '';
      final userName = currentUser?.getStringValue('name') ?? '익명';

      // 첫 번째 이미지만 업로드 (현재 API 제한)
      final imagePath = _selectedImages.isNotEmpty
          ? _selectedImages.first.path
          : null;

      await _service.createPost(
        authorId: userId,
        authorName: userName,
        content: content,
        imagePath: imagePath,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
      );

      // 태그 사용량 증가
      for (final tag in _selectedTags) {
        await _tagService.getOrCreateTag(name: tag);
      }

      // 커뮤니티 목록 새로고침
      if (mounted) {
        context.read<CommunityPostViewModel>().refreshAll();

        _showSnackBar('게시글이 등록되었습니다.', isSuccess: true);
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.data('게시글 등록 실패: $e', isError: true);
      _showSnackBar('게시글 등록에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
      ),
    );
  }

  bool get _canSubmit {
    return _contentController.text.trim().isNotEmpty && !_isSubmitting;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textMain),
          onPressed: () {
            if (_contentController.text.isNotEmpty ||
                _selectedImages.isNotEmpty) {
              _showDiscardDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          '새 게시글',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _canSubmit ? _submitPost : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brand,
                      ),
                    )
                  : Text(
                      '게시',
                      style: AppTextStyles.bodyMediumBold.copyWith(
                        color: _canSubmit
                            ? AppColors.brand
                            : AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 내용 입력 영역
                  _buildContentInput(),

                  // 태그 섹션
                  _buildTagSection(),

                  // 선택된 이미지 미리보기
                  if (_selectedImages.isNotEmpty) _buildImagePreview(),
                ],
              ),
            ),
          ),

          // 하단 툴바
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _contentController,
        decoration: InputDecoration(
          hintText: '무슨 이야기를 나누고 싶으신가요?\n어항 관리 팁, 질문, 일상 등 자유롭게 공유해주세요.',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
            height: 1.5,
          ),
          border: InputBorder.none,
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMain,
          height: 1.5,
        ),
        maxLines: null,
        minLines: 10,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildTagSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          // 태그 헤더
          Row(
            children: [
              Text(
                '태그',
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_selectedTags.length}/$_maxTags)',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showTagSearch = !_showTagSearch;
                    if (!_showTagSearch) {
                      _tagController.clear();
                      _searchedTags = [];
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showTagSearch
                        ? AppColors.brand
                        : AppColors.chipPrimaryBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showTagSearch ? Icons.close : Icons.add,
                        size: 16,
                        color: _showTagSearch ? Colors.white : AppColors.brand,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showTagSearch ? '닫기' : '태그 추가',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: _showTagSearch
                              ? Colors.white
                              : AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 선택된 태그 목록
          if (_selectedTags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTags
                  .map((tag) => _buildSelectedTagChip(tag))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // 태그 검색/입력 영역
          if (_showTagSearch) ...[
            _buildTagSearchField(),
            const SizedBox(height: 8),

            // 검색 결과 또는 인기 태그
            if (_isLoadingTags)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              )
            else if (_searchedTags.isNotEmpty)
              _buildTagSuggestions(_searchedTags, '검색 결과')
            else if (_tagController.text.isEmpty && _popularTags.isNotEmpty)
              _buildTagSuggestions(_popularTags, '인기 태그'),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSelectedTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipPrimaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: Icon(Icons.close, size: 14, color: AppColors.brand),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSearchField() {
    return TextField(
      controller: _tagController,
      decoration: InputDecoration(
        hintText: '태그 검색 또는 입력 (Enter로 추가)',
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.tag, size: 20, color: AppColors.textHint),
        suffixIcon: _tagController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.brand),
                onPressed: () => _addTag(_tagController.text),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.brand),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMain),
      onChanged: (value) {
        setState(() {});
        _searchTags(value);
      },
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          _addTag(value);
        }
      },
    );
  }

  Widget _buildTagSuggestions(List<TagData> tags, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSubtle,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => _buildSuggestionChip(tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(TagData tag) {
    final isSelected = _selectedTags.contains(tag.name);
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          _addTag(tag.name);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand.withValues(alpha: 0.1)
              : AppColors.backgroundApp,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${tag.name}',
              style: AppTextStyles.captionMedium.copyWith(
                color: isSelected ? AppColors.brand : AppColors.textSubtle,
              ),
            ),
            if (tag.usageCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${tag.usageCount}',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColors.textHint,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          Text(
            '첨부 이미지 (${_selectedImages.length}/$_maxImages)',
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          // 이미지 첨부 버튼
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 24,
                    color: _selectedImages.length >= _maxImages
                        ? AppColors.textHint
                        : AppColors.textSubtle,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedImages.length}/$_maxImages',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 글자 수
          Text(
            '${_contentController.text.length}자',
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('작성 취소'),
        content: const Text('작성 중인 내용이 있습니다.\n정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('계속 작성', style: TextStyle(color: AppColors.textSubtle)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: Text('나가기', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
