import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/screens/search.dart';

void main() => runApp(const SmashApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Smash Mobile',
      theme: ThemeData(
        title: 'Smash Mobile',
        theme: ThemeData(
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: MyHomePage(),
        routes: {
          '/home': (_) => MyHomePage(),
          '/login': (_) => const SmashLoginPage(),
        },

      ),
      home: const MyHomePage(title: 'Smash Mobile Home Page'),
    );
}
}
