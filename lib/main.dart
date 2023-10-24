import 'package:flutter/material.dart';
import 'package:namer_app/comms.dart';
import 'package:provider/provider.dart';

import 'debug.dart';
import 'encode.dart';

//import 'dart:convert';



void main() async {

  await initialiseComms();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'DNA Storage App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: "Write"),
                Tab(text: "Read"),
                Tab(text: "Debug"),
              ],
            ),
            title: const Text('DNA Storage App'),
          ),
          body: TabBarView(
            children: [
              EncodingPage(),
              Icon(Icons.directions_car),
              DebugPage(),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}

