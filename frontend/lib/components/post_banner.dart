import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/config/routes/route_names.dart';
import '../config/theme/app_colors.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/db/db_provider.dart';

class PostBanner extends StatefulWidget {
  final Post post;
  final ValueChanged<bool> onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostBanner({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PostBanner> createState() => _PostBannerState();
}

class _PostBannerState extends State<PostBanner> {
  User? _postAuthor;
  bool _isLoadingAuthor = true;
  bool _isExpanded = false;
  late int _likeCount;
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _loadPostAuthor();
    _likeCount = widget.post.likeCount;

    _isLiked = widget.post.isLiked;
  }

  void _handleLike() {
    setState(() {
      if (_isLiked) {
        _likeCount--;
        _isLiked = false;
      } else {
        _likeCount++;
        _isLiked = true;
      }
    });

    widget.onLike(_isLiked);
  }

  Future<void> _loadPostAuthor() async {
    try {
      final author = await DbProvider.instance.getUserById(widget.post.userId);
      if (mounted) {
        setState(() {
          _postAuthor = author;
          _isLoadingAuthor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAuthor = false;
        });
      }
      debugPrint('Failed to load post author: $e');
    }
  }

  Widget _buildPostContent() {
    const int maxLines = 4;

    // Simple approach - check if content has more than 4 lines by character count
    final List<String> lines = widget.post.content.split('\n');
    final bool hasMoreContent = lines.length > maxLines ||
        widget.post.content.length >
            200; // Approximate character limit for 4 lines

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.post.content,
          style: const TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            height: 1.5,
          ),
          maxLines: _isExpanded ? null : maxLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (hasMoreContent && !_isExpanded)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'See more',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.linkedInBlue,
                ),
              ),
            ),
          ),
        if (_isExpanded && hasMoreContent)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'See less',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy  hh:mm a')
        .format(DateTime.parse(widget.post.createdAt));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.darkSurfaceVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Professional User Header
            _buildUserHeader(formattedDate),
            const SizedBox(height: 16),

            // Post Content
            _buildPostContent(),

            // Post Images
            if (widget.post.images.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageGallery(),
            ],

            // Tags Section
            if (widget.post.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTagsSection(),
            ],
            
            const SizedBox(height: 16),
            _buildEngagementStats(),
            const SizedBox(height: 12),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(String formattedDate) {
    return Row(
      children: [
        _isLoadingAuthor
            ? const CircleAvatar(
                radius: 24.0,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, size: 24, color: Colors.red),
              )
            : (_postAuthor?.profilePicture != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: CachedNetworkImage(
                      imageUrl: _postAuthor!.profilePicture!,
                      width: 48.0,
                      height: 48.0,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircleAvatar(
                        radius: 24.0,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.person, size: 24, color: Colors.red),
                      ),
                      errorWidget: (context, url, error) => const CircleAvatar(
                        radius: 24.0,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.person, size: 24, color: Colors.red),
                      ),
                    ),
                  )
                : const CircleAvatar(
                    radius: 24.0,
                    backgroundColor: AppColors.darkSurfaceVariant,
                    child: Icon(Icons.person, size: 24, color: AppColors.darkSecondary),
                  )),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoadingAuthor
                    ? 'Loading...'
                    : (_postAuthor != null
                        ? '${_postAuthor?.userName}'
                        : 'Unknown User'),
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: AppColors.darkSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        _buildPostMenu(),
      ],
    );
  }

  Widget _buildPostMenu() {
    return IconButton(
      icon: const Icon(
        Icons.more_horiz,
        color: AppColors.darkSecondary,
        size: 24,
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.darkSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.darkSecondary,
                  ),
                  title: const Text(
                    'Edit Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await context.pushNamed(
                      RouteNames.postCreation,
                      extra: widget.post,
                    );
                    if (result == true) {
                      widget.onEdit();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete Post',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await DbProvider.instance.deletePost(widget.post.id);
                      widget.onDelete();
                      CustomToast.showSuccess(message: 'Post deleted successfully');
                    } catch (e) {
                      debugPrint('Failed to delete post: $e');
                      CustomToast.showError(
                          message: 'Failed to delete post: ${e.toString()}');
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGallery() {
    if (widget.post.images.length == 1) {
      // Single image - clean, simple design
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: CachedNetworkImage(
          imageUrl: widget.post.images[0].imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 300.0,
          placeholder: (context, url) => Container(
            height: 300,
            color: AppColors.darkSurfaceVariant,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.linkedInBlue,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 300,
            color: AppColors.darkSurfaceVariant,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 50,
                color: AppColors.darkSecondary,
              ),
            ),
          ),
        ),
      );
    } else {
      // Multiple images - simple horizontal scroll
      return SizedBox(
        height: 250.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.post.images.length,
          itemBuilder: (context, index) {
            final image = widget.post.images[index];
            return Container(
              margin: EdgeInsets.only(
                right: index < widget.post.images.length - 1 ? 8.0 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: image.imageUrl,
                  fit: BoxFit.cover,
                  width: 200.0,
                  height: 250.0,
                  placeholder: (context, url) => Container(
                    width: 200,
                    color: AppColors.darkSurfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.linkedInBlue,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 200,
                    color: AppColors.darkSurfaceVariant,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: AppColors.darkSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildTagsSection() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: widget.post.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.darkBackground,
              width: 1,
            ),
          ),
          child: Text(
            '#$tag',
            style: const TextStyle(
              color: AppColors.linkedInBlue,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEngagementStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF4A4A4A), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (_likeCount > 0) ...[
            Icon(
              Icons.thumb_up,
              size: 16,
              color: AppColors.linkedInBlue,
            ),
            const SizedBox(width: 6),
            Text(
              '$_likeCount',
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.darkSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          const Spacer(),
          if (widget.post.commentCount > 0)
            Text(
              '${widget.post.commentCount} comments',
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.darkSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            'Like',
            _handleLike,
            _isLiked ? AppColors.linkedInBlue : AppColors.darkSecondary,
          ),
        ),
        Expanded(
          child: _buildActionButton(
            Icons.comment_outlined,
            'Comment',
            widget.onComment,
            AppColors.darkSecondary,
          ),
        ),
        Expanded(
          child: _buildActionButton(
            Icons.share_outlined,
            'Share',
            widget.onShare,
            AppColors.darkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
