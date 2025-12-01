import 'package:flutter/material.dart';
import 'package:smash_mobile/widgets/post_card.dart';
import 'package:smash_mobile/widgets/comment_card.dart';
import 'package:smash_mobile/screens/post_detail.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PostCard(
              title: "Hello World!",
              content:
                  "Lorem Ipsum dolor sit amet blababla bleblele blobloblo haup blulululluullullu",
              author: "Jane Doe",
              image: Image.network(
                'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d',
              ),
              likeCount: 3,
              dislikeCount: 1,
              commentCount: 10,
              timestamp: DateTime.now(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      title: "Hello World!",
                      content:
                          "Lorem Ipsum dolor sit amet blababla bleblele blobloblo haup blulululluullullu",
                      author: "Jane Doe",
                      image: Image.network(
                        'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d',
                      ),
                      likeCount: 3,
                      dislikeCount: 1,
                      commentCount: 10,
                      timestamp: DateTime.now(),
                    ),
                  ),
                );
              },
            ),
            CommentCard(
              content: "This is a great post! I really enjoyed reading it.",
              author: "John Smith",
              likeCount: 5,
              dislikeCount: 0,
              timestamp: DateTime.now(),
              onTap: () {
                print("Comment tapped");
              },
            ),
            CommentCard(
              content: "Thanks for sharing this information!",
              author: "Alice Johnson",
              profileImage: Image.network(
                'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
              ),
              likeCount: 2,
              dislikeCount: 1,
              timestamp: DateTime.now().subtract(Duration(hours: 2)),
              onTap: () {
                print("Comment tapped");
              },
            ),
          ],
        ),
      ),
    );
  }
}
