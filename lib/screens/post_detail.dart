import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final Image? profileImage;
  final Image? image;
  final String author;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final DateTime timestamp;

  const PostDetailScreen({
    super.key,
    required this.title,
    required this.content,
    this.profileImage,
    this.image,
    required this.author,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                          author,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Posted on: ${timestamp.toLocal()}',
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
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (image != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image,
                  ),
                ),
              const SizedBox(height: 16),
              Text(content, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.thumb_up, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('$likeCount'),
                  const SizedBox(width: 16),
                  Icon(Icons.thumb_down, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('$dislikeCount'),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('$commentCount'),
                  const SizedBox(width: 16),
                  Icon(Icons.bookmark, size: 16, color: Colors.black),
                  Spacer(),
                  Icon(Icons.share, size: 16, color: Colors.black),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
