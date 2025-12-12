import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smash_mobile/models/post.dart';
import 'package:smash_mobile/models/comment.dart';
import 'package:smash_mobile/widgets/comment_card.dart';
import 'package:smash_mobile/services/post_service.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  final Image? profileImage;

  const PostDetailScreen({super.key, required this.post, this.profileImage});

  // Use PostService to fetch comments

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  profileImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: profileImage,
                          ),
                        )
                      : CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: Colors.grey[600],
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Posted on: ${post.createdAt.toLocal()}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (post.imageUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(post.imageUrl.toString()),
                  ),
                ),
              const SizedBox(height: 16),
              Text(post.content, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.thumb_up, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.thumb_down, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('${post.dislikesCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('${post.sharesCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.bookmark, size: 16, color: Colors.black),
                  Spacer(),
                  Icon(Icons.share, size: 16, color: Colors.black),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Comment>>(
                future: PostService().fetchComments(post.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading comments: ${snapshot.error}'),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No comments'));
                  }

                  final comments = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final c = comments[idx];
                      return CommentCard(comment: c, onTap: () {});
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
