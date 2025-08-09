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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_comments.isEmpty) {
      return const Center(
          child:
              Text("No comments yet.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final commentResponse = _comments[index];
        return _CommentItem(
          key: ValueKey(
              commentResponse.comment.id), // Add key for better performance
          commentResponse: commentResponse,
          currentUserId: widget.currentUserId,
          onReply: (commentId) {
            setState(() {
              _editingCommentId = null; // Exit editing mode if active
              _replyingToCommentId = commentId;
              FocusScope.of(context).requestFocus();
            });
          },
          onEdit: (comment) {
            setState(() {
              _replyingToCommentId = null; // Exit reply mode if active
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
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() => const Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Comments',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing || isReplying)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? "Editing your comment..." : "Replying...",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  InkWell(
                    onTap: _cancelActions,
                    child: Row(
                      children: [
                        Text("Cancel",
                            style: TextStyle(
                                color: Colors.blue[300], fontSize: 12)),
                        const SizedBox(width: 4),
                        Icon(Icons.close, color: Colors.blue[300], size: 16),
                      ],
                    ),
                  )
                ],
              ),
            ),
          Row(
            children: [
              const CircleAvatar(
                radius: 18.0,
                backgroundColor: Color(0xFF3A3A3A),
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    AppColors.linkedInBlue,
                    AppColors.linkedInBlueLight
                  ]),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: Icon(isEditing ? Icons.check : Icons.send,
                      color: Colors.white),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20.0,
                backgroundColor: const Color(0xFF3A3A3A),
                backgroundImage:
                    userImageUrl != null ? NetworkImage(userImageUrl) : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : (userImageUrl == null
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 20)
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
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // FIX: Added timestamp back for better UI
                        Text(
                          '2h', // Replace with a real timestamp calculation
                          style: TextStyle(
                              fontSize: 12.0, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment.content,
                      style: const TextStyle(
                          fontSize: 14.0, color: Colors.white, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => widget.onReply(comment.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.reply,
                                size: 16, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isAuthor)
                PopupMenuButton<String>(
                  icon:
                      Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
                  color: const Color(0xFF3A3A3A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.onEdit(comment);
                    } else if (value == 'delete') {
                      widget.onDelete(comment.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child:
                          Text("Edit", style: TextStyle(color: Colors.white)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text("Delete",
                          style: TextStyle(color: Colors.red[400])),
                    ),
                  ],
                ),
            ],
          ),
          // --- FULLY CORRECTED REPLIES SECTION ---
          if (widget.commentResponse.totalReplyCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showReplies)
                    ...widget.commentResponse.replies.map((replyComment) {
                      // FIX: Wrapping the 'Comment' object in a 'CommentResponse'
                      return _CommentItem(
                        key: ValueKey(replyComment.id), // FIX: Corrected typo
                        commentResponse: CommentResponse(
                          comment: replyComment,
                          replies: const [], // Nested replies don't show more
                          replyCount: 0,
                          totalReplyCount: 0,
                        ),
                        currentUserId: widget.currentUserId,
                        onReply: widget.onReply,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                      );
                    }),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () =>
                        setState(() => _showReplies = !_showReplies),
                    child: Text(
                      _showReplies
                          ? "Hide replies"
                          // FIX: Using totalReplyCount for accurate display
                          : "View ${widget.commentResponse.totalReplyCount} replies",
                      style: TextStyle(
                          color: Colors.blue[300], fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
