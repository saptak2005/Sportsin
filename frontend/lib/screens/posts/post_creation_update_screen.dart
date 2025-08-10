import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/models/post.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/utils/image_picker_util.dart';
import 'package:sportsin/config/theme/app_colors.dart';

import '../../components/custom_toast.dart';

class PostCreationAndUpdateScreen extends StatefulWidget {
  final Post? existingPost;

  const PostCreationAndUpdateScreen({super.key, this.existingPost});

  @override
  State<PostCreationAndUpdateScreen> createState() =>
      _PostCreationAndUpdateScreenState();
}

class _PostCreationAndUpdateScreenState
    extends State<PostCreationAndUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController contentController = TextEditingController();
  List<File> selectedImages = [];
  bool isLoading = false;
  bool replaceExistingImages = false;
  bool get isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.existingPost != null) {
      final post = widget.existingPost!;
      contentController.text = post.content;
    }
  }

  List<String> _extractHashtags(String text) {
    final RegExp hashTagRegExp = RegExp(r"#\w+");

    final hashtags = hashTagRegExp
        .allMatches(text)
        .map((match) => match.group(0)!.substring(1))
        .toSet()
        .toList();

    return hashtags;
  }

  void _createOrUpdatePost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      final String content = contentController.text.trim();

      final List<String> extractedTags = _extractHashtags(content);

      try {
        if (isEditing) {
          final updatedPost = widget.existingPost!.copyWith(
            content: contentController.text.trim(),
            tags: extractedTags,
          );

          await DbProvider.instance.updatePost(
            updatedPost,
            newImages: selectedImages.isNotEmpty ? selectedImages : null,
            replaceImages: replaceExistingImages,
          );

          if (mounted) {
            CustomToast.showSuccess(message: 'Post updated successfully!');
            context.pop(true);
          }
        } else {
          // Create new post
          await DbProvider.instance.createPost(
            content: contentController.text.trim(),
            tags: extractedTags,
            images: selectedImages,
          );

          if (mounted) {
            CustomToast.showSuccess(message: 'Post created successfully!');
            context.pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          CustomToast.showError(
              message:
                  'Failed to ${isEditing ? 'update' : 'create'} post: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  void _pickMultipleImages() async {
    final List<File>? images =
        await ImagePickerUtil.showMultipleImagePickerDialog(context);
    if (images != null && images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Edit Post' : 'Create Post',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isLoading)
            TextButton(
              onPressed: _createOrUpdatePost,
              child: Text(
                isEditing ? 'Update' : 'Post',
                style: const TextStyle(
                  color: AppColors.linkedInBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.linkedInBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Content Input Section
                    _buildContentSection(),

                    // Images Section
                    _buildImagesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4A4A4A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: AppColors.linkedInBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit your post' : 'What\'s on your mind?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: contentController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
              maxLines: 8,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black,
                hintText:
                    'Share your thoughts, experiences, or opportunities...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Content is required' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Add Images Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4A4A4A),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.linkedInGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: AppColors.linkedInGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add Photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickMultipleImages,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.linkedInBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedImages.isNotEmpty
                                    ? 'Add More'
                                    : 'Select',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Show existing images for editing
                if (isEditing && widget.existingPost!.images.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildExistingImagesSection(),
                ],

                // Show newly selected images
                if (selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSelectedImagesSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Current Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: replaceExistingImages
                    ? AppColors.linkedInBlue.withOpacity(0.1)
                    : AppColors.darkSurfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: replaceExistingImages
                      ? AppColors.linkedInBlue
                      : const Color(0xFF4A4A4A),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: replaceExistingImages,
                    onChanged: (value) {
                      setState(() {
                        replaceExistingImages = value ?? false;
                      });
                    },
                    fillColor: MaterialStateProperty.all(
                      replaceExistingImages ? AppColors.linkedInBlue : AppColors.darkSecondary,
                    ),
                    side: BorderSide.none,
                  ),
                  Text(
                    'Replace all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: replaceExistingImages 
                          ? AppColors.linkedInBlue 
                          : AppColors.darkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.existingPost!.images.length,
            itemBuilder: (context, index) {
              final image = widget.existingPost!.images[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: replaceExistingImages
                              ? AppColors.linkedInBlue
                              : const Color(0xFF4A4A4A),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          image.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: AppColors.darkSurfaceVariant,
                              child: Icon(
                                Icons.broken_image,
                                size: 30,
                                color: AppColors.darkSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (replaceExistingImages)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.linkedInBlue,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isEditing ? 'New Images to Add' : 'Selected Images',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.linkedInGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${selectedImages.length}',
                style: const TextStyle(
                  color: AppColors.linkedInGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.linkedInGreen,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.linkedInBlue,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
