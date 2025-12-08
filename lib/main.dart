import 'package:flutter/material.dart';
import 'package:smash_mobile/models/post.dart';
import 'package:smash_mobile/services/post_service.dart';
import 'package:smash_mobile/widgets/post_card.dart';
import 'package:smash_mobile/screens/post_detail.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smash Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Smash Mobile Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Post>> _postsFuture;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final post = snapshot.data![index];
                // Construct image URL if image exists
                // Assuming the image path from Django starts with /media/
                final imageUrl = post.image != null
                    ? 'http://127.0.0.1:8000${post.image}'
                    : null;

                return PostCard(
                  title: post.title,
                  content: post.content,
                  author: post.user,
                  image: imageUrl != null ? Image.network(imageUrl) : null,
                  likeCount: post.likesCount,
                  dislikeCount: post.dislikesCount,
                  commentCount: post.commentCount,
                  timestamp: post.createdAt,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(
                          title: post.title,
                          content: post.content,
                          author: post.user,
                          image: imageUrl != null
                              ? Image.network(imageUrl)
                              : null,
                          likeCount: post.likesCount,
                          dislikeCount: post.dislikesCount,
                          commentCount: post.commentCount,
                          timestamp: post.createdAt,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
