// ignore_for_file: deprecated_member_use, unused_field

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_api.dart';
import 'package:smash_mobile/models/comment_entry.dart';
import 'package:smash_mobile/widgets/comment_card.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/widgets/post_card.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smash_mobile/navigation.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final int postId;
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PostApi _api;
  late ProfileApi _profileApi;
  ProfileFeedItem? _item;
  bool _loading = true;
  String? _error;
  int? _currentUserId;
  bool _hasChanges = false;
  // Comments
  List<Comment> _comments = [];
  bool _loadingComments = true;
  String? _commentsError;
  final TextEditingController _commentController = TextEditingController();

  // NEW: Modern colors
  static const Color _primaryColor = Color(0xFF667EEA);
  static const Color _secondaryColor = Color(0xFF764BA2);

  String? _resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('/')) return '${_api.baseUrl}$trimmed';
    return '${_api.baseUrl}/$trimmed';
  }

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _api = PostApi(request: request);
    _profileApi = ProfileApi(request: request);
    // Load post details immediately, but ensure we fetch current user
    // before loading comments so the API can include `userReaction`.
    _load();
    _loadCurrentUser().whenComplete(() {
      _loadComments();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modal = ModalRoute.of(context);
    if (modal != null) routeObserver.subscribe(this, modal);
  }

  @override
  void dispose() {
    _commentController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Returned to this page (e.g., after editing) — refresh data
    _load();
    _loadComments();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final me = await _profileApi.fetchProfile();
      if (!mounted) return;
      setState(() {
        _currentUserId = me.id;
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchPostDetail(widget.postId);
      if (!mounted) return;
      setState(() {
        _item = data as ProfileFeedItem?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });
    try {
      final list = await _api.fetchComments(
        widget.postId,
        userId: _currentUserId,
      );
      if (!mounted) return;
      setState(() {
        _comments = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commentsError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingComments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const LeftDrawer(),
        // NEW: Gradient background
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(_hasChanges),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _handleShare,
                  ),
                ],
              ),
              SliverToBoxAdapter(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_item == null) {
      return _buildEmptyState();
    }

    final item = _item!;
    final avatar = _api.resolveMediaUrl(item.profilePhoto);
    final defaultAvatar =
        _api.resolveMediaUrl('/static/images/user-profile.png') ??
        '${_api.baseUrl}/static/images/user-profile.png';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Glassmorphism card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: PostCard(
              item: item,
              avatarUrl: avatar,
              imageUrl: _api.resolveMediaUrl(item.image),
              defaultAvatar: defaultAvatar,
              resolveAvatar: _api.resolveMediaUrl,
              showMenu: true,
              currentUserId: _currentUserId,
              showFooterActions: true,
              enableInteractions: true,
              profilePageBuilder: (id) => ProfilePage(userId: id),
              // NEW: Interaction handlers
              onShare: _handleShare,
              onEdit: (_) async {
                _hasChanges = true;
                await _load();
              },
              onLike: () => _hasChanges = true,
              onDislike: () => _hasChanges = true,
              onSave: () => _hasChanges = true,
              onDelete: _handleDeletePost,
              // Disable tap on detail page (avoid recursion)
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          // Comments section
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Post not found',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: _primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _submitComment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_loadingComments)
            const Center(child: CircularProgressIndicator())
          else if (_commentsError != null)
            Text(_commentsError!, style: TextStyle(color: Colors.red.shade700))
          else if (_comments.isEmpty)
            Text(
              'No comments yet. Be the first!',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            Column(
              children: _comments.map((c) {
                final idStr = c.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: CommentCard(
                    id: idStr,
                    author: c.author,
                    content: c.content,
                    avatarUrl: _api.resolveMediaUrl(c.profilePhoto),
                    createdAt: c.createdAt,
                    likes: c.likesCount,
                    dislikes: c.dislikesCount,
                    userReaction: c.userReaction,
                    userId: c.userId,
                    onLike: () async {
                      try {
                        await _api.interactWithComment(idStr, 'like');
                        await _loadComments();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to like: $e')),
                        );
                      }
                    },
                    onDislike: () async {
                      try {
                        await _api.interactWithComment(idStr, 'dislike');
                        await _loadComments();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to dislike: $e')),
                        );
                      }
                    },
                    onProfileTap: () {
                      if (!mounted) return;
                      if (c.userId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(userId: c.userId),
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      if (!mounted) return;
      setState(() {
      });
      await _api.createComment(widget.postId, text, userId: _currentUserId);
      _hasChanges = true;
      await _load();
      _commentController.clear();
      await _loadComments();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment posted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
    }
  }

  Future<void> _handleShare() async {
    if (!mounted) return;
    final request = context.read<CookieRequest>();
    final baseUrl = ProfileApi(request: request).baseUrl;
    final postId = _item?.id ?? widget.postId;
    final shareUrl = '$baseUrl/post/$postId/';
    final shareText = 'Check out this post on Smash!\n$shareUrl';
    await Clipboard.setData(ClipboardData(text: shareUrl));
    await Share.share(
      shareText,
      subject: _item?.title.isNotEmpty == true ? _item!.title : 'Smash post',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  Future<void> _handleDeletePost(ProfileFeedItem post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.deletePost(post.id);
      if (!mounted) return;
      _hasChanges = true;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post: $e')),
      );
    }
  }
}
