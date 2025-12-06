// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/main_offline.dart';
import 'package:yplayer/providers/search_provider.dart';
import 'package:yplayer/providers/player_provider.dart';

import 'package:yplayer/screens/online/beranda.dart';
import 'package:yplayer/screens/online/favorit.dart';
// ignore: unused_import
import 'package:yplayer/screens/online/musik.dart';
import 'package:yplayer/screens/online/teratas.dart';
import 'package:yplayer/screens/search/search_page.dart';
import 'package:yplayer/widgets/mini_player_widget.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SearchProvider()),
        ChangeNotifierProvider(
          create: (context) => PlayerProvider(audioHandler: null),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HalamanUtama(),
    );
  }
}

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _judulTab = ["Beranda", "Musik", "Favorit", "Teratas"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_judulTab[_tabController.index]),
        foregroundColor: Colors.white,
        backgroundColor: Colors.pink,
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(icon: Icon(Icons.home)),
            Tab(icon: Icon(Icons.music_note)),
            Tab(icon: Icon(Icons.star)),
            Tab(icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Image.asset("assets/images/image.png")),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Online Mode"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text("Offline Mode"),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HalamanUtamaOffline(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: const [
              BerandaPageOnline(),
              // MusikPageOnline(),
              FavoritPageOnline(),
              TeratasPageOnline(),
            ],
          ),
           Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayerWidget(),
          ),
        ],
      ),
    );
  }
}
