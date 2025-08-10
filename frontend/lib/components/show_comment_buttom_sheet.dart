import 'package:flutter/material.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/config/theme/app_colors.dart';
import 'package:sportsin/models/comment_model.dart';
import 'package:sportsin/models/user.dart';
import 'package:sportsin/services/db/db_provider.dart';

class CommentSheet extends StatefulWidget {
  final String postId;
  final String currentUserId; // IMPORTANT: Pass the current user's ID here

  const CommentSheet({
    super.key,
    required this.postId,
    required this.currentUserId,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();

  List<CommentResponse> _comments = [];
  bool _isLoading = true;
  String? _error;

  // State for replying and editing
  String? _replyingToCommentId;
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final comments =
          await DbProvider.instance.getCommentsByPostId(postId: widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load comments.";
          _isLoading = false;
        });
      }
    }
  }

  void _cancelActions() {
    setState(() {
      _replyingToCommentId = null;
      _editingCommentId = null;
      _commentController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final content = _commentController.text.trim();
    FocusScope.of(context).unfocus();

    try {
      if (_editingCommentId != null) {
        await DbProvider.instance.updateComment(
          commentId: _editingCommentId!,
          content: content,
        );
      } else {
        await DbProvider.instance.createComment(
          postId: widget.postId,
          content: content,
          parentCommentId: _replyingToCommentId,
        );
      }
      _cancelActions();
      await _fetchComments();
    } catch (e) {
      if (mounted) {
        CustomToast.showError(message: e.toString());
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await DbProvider.instance.deleteComment(commentId);
      setState(() {
        _comments.removeWhere((c) => c.comment.id == commentId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete comment.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
            border: Border.all(
              color: AppColors.darkSurfaceVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandleBar(),
              _buildHeader(),
              Expanded(child: _buildBody(scrollController)),
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.linkedInBlue,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.darkSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              "No comments yet",
              style: TextStyle(
                color: AppColors.darkSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to comment!",
              style: TextStyle(
                color: AppColors.darkSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final commentResponse = _comments[index];
        return _CommentItem(
          key: ValueKey(commentResponse.comment.id),
          commentResponse: commentResponse,
          currentUserId: widget.currentUserId,
          onReply: (commentId) {
            setState(() {
              _editingCommentId = null;
              _replyingToCommentId = commentId;
              FocusScope.of(context).requestFocus();
            });
          },
          onEdit: (comment) {
            setState(() {
              _replyingToCommentId = null;
              _editingCommentId = comment.id;
              _commentController.text = comment.content;
              FocusScope.of(context).requestFocus();
            });
          },
          onDelete: _deleteComment,
        );
      },
    );
  }

  Widget _buildHandleBar() => Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.darkSecondary,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF4A4A4A), width: 1),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'Comments',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _buildCommentInput() {
    final isEditing = _editingCommentId != null;
    final isReplying = _replyingToCommentId != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: Color(0xFF4A4A4A), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing || isReplying)
            Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? "Editing comment" : "Replying to comment",
                    style: TextStyle(
                      color: AppColors.darkSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelActions,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Cancel",
                          style: TextStyle(
                            color: AppColors.linkedInBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.close,
                          color: AppColors.linkedInBlue,
                          size: 16,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const CircleAvatar(
                radius: 20.0,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4A4A4A),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: AppColors.darkSecondary,
                        fontSize: 14,
                      ),
                      fillColor: Colors.grey[900],
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.linkedInBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: Icon(
                    isEditing ? Icons.check : Icons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: _submitComment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatefulWidget {
  final CommentResponse commentResponse;
  final String currentUserId;
  final Function(String) onReply;
  final Function(Comment) onEdit;
  final Function(String) onDelete;

  const _CommentItem({
    super.key,
    required this.commentResponse,
    required this.currentUserId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  User? _user;
  bool _isLoading = true;
  bool _showReplies = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final userId = widget.commentResponse.comment.userId;
      if (userId.isNotEmpty) {
        final user = await DbProvider.instance.getUserById(userId);
        if (mounted) {
          setState(() {
            _user = user;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.commentResponse.comment;
    final isAuthor = comment.userId == widget.currentUserId;
    final userName = _user?.userName ?? 'Anonymous';
    final userImageUrl = _user?.profilePicture;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4A4A4A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18.0,
                backgroundColor: AppColors.darkSurfaceVariant,
                backgroundImage:
                    userImageUrl != null ? NetworkImage(userImageUrl) : null,
                child: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.linkedInBlue,
                        ),
                      )
                    : (userImageUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.darkSecondary, size: 18)
                        : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.darkSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '2h', // Replace with a real timestamp calculation
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.darkSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.content,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.thumb_up_outlined,
                          label: 'Like',
                          onTap: () {},
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          icon: Icons.reply_outlined,
                          label: 'Reply',
                          onTap: () => widget.onReply(comment.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAuthor)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: AppColors.darkSecondary,
                    size: 20,
                  ),
                  color: AppColors.darkSurface,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.onEdit(comment);
                    } else if (value == 'delete') {
                      widget.onDelete(comment.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                               color: AppColors.darkSecondary, size: 18),
                          const SizedBox(width: 12),
                          const Text("Edit",
                                style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                               color: AppColors.linkedInBlue, size: 18),
                          const SizedBox(width: 12),
                          Text("Delete",
                               style: TextStyle(color: AppColors.linkedInBlue)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // --- REPLIES SECTION ---
          if (widget.commentResponse.totalReplyCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showReplies)
                    ...widget.commentResponse.replies.map((replyComment) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _CommentItem(
                          key: ValueKey(replyComment.id),
                          commentResponse: CommentResponse(
                            comment: replyComment,
                            replies: const [],
                            replyCount: 0,
                            totalReplyCount: 0,
                          ),
                          currentUserId: widget.currentUserId,
                          onReply: widget.onReply,
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                        ),
                      );
                    }),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () =>
                        setState(() => _showReplies = !_showReplies),
                    icon: Icon(
                      _showReplies ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.linkedInBlue,
                      size: 18,
                    ),
                    label: Text(
                      _showReplies
                          ? "Hide replies"
                          : "View ${widget.commentResponse.totalReplyCount} replies",
                      style: TextStyle(
                        color: AppColors.linkedInBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.darkSecondary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.darkSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
