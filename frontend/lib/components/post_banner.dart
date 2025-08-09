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
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
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
            child: const Padding(
              padding: EdgeInsets.only(top: 5.0),
              child: Text(
                'Show more',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
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
            child: const Padding(
              padding: EdgeInsets.only(top: 5.0),
              child: Text(
                'Show less',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
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
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E1E),
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.linkedInBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced User Info Section
              _buildUserHeader(formattedDate),
              const SizedBox(height: 20),

              // Post Content with better styling
              _buildPostContent(),

              // Post Images with improved layout
              if (widget.post.images.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildImageGallery(),
              ],

              // Enhanced Tags Section
              if (widget.post.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildTagsSection(),
              ],
              const SizedBox(height: 20),
              _buildEngagementStats(),
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: _isLoadingAuthor
                    ? const CircleAvatar(
                        radius: 28.0,
                        backgroundColor: Color(0xFF3A3A3A),
                        child:
                            Icon(Icons.person, size: 28, color: Colors.white),
                      )
                    : (_postAuthor?.profilePicture != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(28.0),
                            child: CachedNetworkImage(
                              imageUrl: _postAuthor!.profilePicture!,
                              width: 56.0,
                              height: 56.0,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircleAvatar(
                                radius: 28.0,
                                backgroundColor: Color(0xFF3A3A3A),
                                child: Icon(Icons.person,
                                    size: 28, color: Colors.white),
                              ),
                              errorWidget: (context, url, error) =>
                                  const CircleAvatar(
                                radius: 28.0,
                                backgroundColor: Color(0xFF3A3A3A),
                                child: Icon(Icons.person,
                                    size: 28, color: Colors.white),
                              ),
                            ),
                          )
                        : const CircleAvatar(
                            radius: 28.0,
                            backgroundColor: Color(0xFF3A3A3A),
                            child: Icon(Icons.person,
                                size: 28, color: Colors.white),
                          )),
              ),
            ],
          ),
          const SizedBox(width: 16),
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
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildPostMenu(),
        ],
      ),
    );
  }

  Widget _buildPostMenu() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF2A2A2A),
        onSelected: (value) async {
          if (value == 'Edit') {
            final result = await context.pushNamed(
              RouteNames.postCreation,
              extra: widget.post,
            );

            if (result == true) {
              widget.onEdit();
            }
          } else if (value == 'Delete') {
            try {
              await DbProvider.instance.deletePost(widget.post.id);
              widget.onDelete();
              CustomToast.showSuccess(message: 'Post deleted successfully');
            } catch (e) {
              debugPrint('Failed to delete post: $e');
              CustomToast.showError(
                  message: 'Failed to delete post: ${e.toString()}');
            }
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'Edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.grey[300], size: 20),
                const SizedBox(width: 12),
                Text(
                  'Edit Post',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'Delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.post.images.length == 1) {
      // Single image - full width
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: CachedNetworkImage(
          imageUrl: widget.post.images[0].imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 250.0,
          placeholder: (context, url) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    } else {
      // Multiple images - horizontal scroll
      return SizedBox(
        height: 220.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.post.images.length,
          itemBuilder: (context, index) {
            final image = widget.post.images[index];
            return Container(
              margin: EdgeInsets.only(
                right: index < widget.post.images.length - 1 ? 12.0 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: CachedNetworkImage(
                  imageUrl: image.imageUrl,
                  fit: BoxFit.cover,
                  width: 200.0,
                  height: 220.0,
                  placeholder: (context, url) => Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 50,
                        color: Colors.grey,
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
            gradient: LinearGradient(
              colors: [
                AppColors.linkedInBlue.withOpacity(0.8),
                AppColors.linkedInBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.linkedInBlue.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '#$tag',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEngagementStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: Colors.red[400],
              ),
              const SizedBox(width: 6),
              Text(
                '$_likeCount Likes',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Colors.blue[400],
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.post.commentCount} Comments',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.share,
                size: 16,
                color: Colors.green[400],
              ),
              const SizedBox(width: 6),
              const Text(
                '5 Shares',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
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
            _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_outlined,
            'Like',
            _handleLike,
            _isLiked ? Colors.red : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            Icons.chat_bubble_outline,
            'Comment',
            widget.onComment,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            Icons.share_outlined,
            'Share',
            widget.onShare,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed, Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: accentColor,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
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
