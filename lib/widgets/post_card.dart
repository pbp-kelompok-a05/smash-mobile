import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String title;
  final String content;
  final Image? image;
  final String author;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final DateTime timestamp;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.title,
    required this.content,
    this.image,
    required this.author,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image != null)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 50,
                        height: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: image,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by $author - ${timestamp.toLocal()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(content, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
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
      ),
    );
  }
}
