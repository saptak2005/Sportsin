import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsin/components/post_banner.dart';
import 'package:sportsin/components/show_comment_buttom_sheet.dart';
import 'package:sportsin/config/routes/route_names.dart';
import 'package:sportsin/models/post.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'package:sportsin/components/custom_toast.dart';

class FeedScreen extends StatefulWidget {
  final bool fromProfileScreen;
  final String? userId;
  const FeedScreen({
    super.key,
    this.userId,
    this.fromProfileScreen = false,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMorePosts = true;
  int _currentOffset = 0;
  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMorePosts) {
        _loadMorePosts();
      }
    }
  }

  void _onLike(Post post, bool isNowLiked) async {
    try {
      if (isNowLiked) {
        await DbProvider.instance.likePost(post.id);
      } else {
        await DbProvider.instance.unlikePost(post.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final postIndex = _posts.indexWhere((p) => p.id == post.id);
          if (postIndex != -1) {
            final originalPost = _posts[postIndex];
            _posts[postIndex] = originalPost.copyWith(
              likeCount: isNowLiked
                  ? originalPost.likeCount - 1
                  : originalPost.likeCount + 1,
              isLiked: !isNowLiked,
            );
          }
        });
        CustomToast.showError(message: 'Action failed. Please try again.');
      }
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final posts = widget.fromProfileScreen
          ? await DbProvider.instance.getMyPosts(
              limit: _limit,
              offset: 0,
            )
          : await DbProvider.instance.getPostWithPagination(
              limit: _limit,
              offset: 0,
            );

      setState(() {
        _posts = posts;
        _currentOffset = posts.length;
        _hasMorePosts = posts.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
          message: 'Failed to load posts: ${e.toString()}',
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMorePosts) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPosts = await DbProvider.instance.getPostWithPagination(
        limit: _limit,
        offset: _currentOffset,
      );

      setState(() {
        _posts.addAll(newPosts);
        _currentOffset += newPosts.length;
        _hasMorePosts = newPosts.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
          message: 'Failed to load more posts: ${e.toString()}',
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _currentOffset = 0;
      _hasMorePosts = true;
    });
    await _loadPosts();
  }

  void _onComment(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentSheet(postId: post.id, currentUserId: widget.userId!),
    );
  }

  void _onShare(Post post) {
    // TODO: Implement share functionality
    CustomToast.showInfo(message: 'Share functionality coming soon!');
  }

  void _onEditPost(Post post) async {
    await _refreshPosts();
  }

  void _onDeletePost(Post post) {
    setState(() {
      _posts.removeWhere((p) => p.id == post.id);
      _currentOffset = _posts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshPosts,
            child: Column(
              children: [
                Expanded(
                  child: _posts.isEmpty && !_isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.post_add,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No posts yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Be the first to create a post!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  context
                                      .pushNamed(RouteNames.postCreation)
                                      .then((_) {
                                    _refreshPosts();
                                  });
                                },
                                child: const Text('Create First Post'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              // Loading indicator at bottom
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            // Reverse the order of posts
                            final post = _posts[_posts.length - 1 - index];
                            return PostBanner(
                              post: post,
                              onLike: (isLiked) => _onLike(post, isLiked),
                              onComment: () => _onComment(post),
                              onShare: () => _onShare(post),
                              onEdit: () => _onEditPost(post),
                              onDelete: () => _onDeletePost(post),
                            );
                          },
                        ),
                ),
                // Loading indicator for initial load
                if (_isLoading && _posts.isEmpty)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
