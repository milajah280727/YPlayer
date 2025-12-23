import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/app_theme.dart';
import 'package:yplayer/providers/search_provider.dart';
import 'package:yplayer/providers/player_provider.dart';
import 'package:yplayer/screens/online/beranda.dart';
import 'package:yplayer/screens/online/favorit.dart';
import 'package:yplayer/screens/online/musik.dart';
import 'package:yplayer/screens/online/teratas.dart';
import 'package:yplayer/screens/search/search_page.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/mini_player_widget.dart';
import 'package:yplayer/main_offline.dart';

void main() {
  DownloadService.init();
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
      title: 'YPlayer',
      theme: AppTheme.darkTheme,
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final padding = MediaQuery.of(context).padding;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.background,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          Column(
           
            children: [
              _buildCustomAppBar(context, padding),
              Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      BerandaPageOnline(),
                      MusikPageOnline(),
                      FavoritPageOnline(),
                      TeratasPageOnline(),
                    ],
                  ),
                ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayerWidget(),
          ),
        ],
      ),
    );
  }


  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsetsGeometry.only(top: 50),
            child: Column(
              children: [
                Image.asset("assets/images/onlineimage.png",width: 80,height: 80,),
                SizedBox(height: 5,),
                Text("YPlayer")
              ],
            )
          ),
          ListTile(
            leading: Icon(Icons.wifi, color: AppTheme.primaryPink),
            title: const Text('Online Mode'),
            subtitle: const Text('Stream and download music'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.offline_bolt, color: AppTheme.textSecondary),
            title: const Text('Offline Mode'),
            subtitle: const Text('Play downloaded music'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanUtamaOffline(),
                ),
                (route) => false,
              );
            },
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, EdgeInsets padding) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: padding.top, left: 8.0, right: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Text(
                  _judulTab[_tabController.index],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchPage()),
                    );
                  },
                ),
              ],
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.home_outlined)),
                Tab(icon: Icon(Icons.music_note_outlined)),
                Tab(icon: Icon(Icons.favorite_outline)),
                Tab(icon: Icon(Icons.trending_up_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}