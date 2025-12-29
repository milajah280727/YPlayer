// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:yplayer/app_theme.dart';
import 'package:yplayer/main.dart';
import 'package:yplayer/screens/offline/beranda.dart';
import 'package:yplayer/screens/offline/playlist_page_offline.dart';
import 'package:yplayer/widgets/mini_player_widget.dart';

void main() {
  runApp(const MyAppOffline());
}

class MyAppOffline extends StatelessWidget {
  const MyAppOffline({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YPlayer - Offline',
      theme: AppTheme.darkTheme,
      home: const HalamanUtamaOffline(),
    );
  }
}

class HalamanUtamaOffline extends StatefulWidget {
  const HalamanUtamaOffline({super.key});

  @override
  State<HalamanUtamaOffline> createState() => _HalamanUtamaOfflineState();
}

class _HalamanUtamaOfflineState extends State<HalamanUtamaOffline>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _judulTab = ["Hasil Unduhan",];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCustomAppBar(context, padding),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: padding.bottom + 70),
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      BerandaPageOffline(),
                      
                    ],
                  ),
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
                Image.asset("assets/images/offlineimage.png",width: 80,height: 80,),
                SizedBox(height: 5,),
                Text("YPlayer")
              ],
            )
          ),
          ListTile(
            leading: Icon(Icons.wifi, color: AppTheme.textSecondary),
            title: const Text('Online Mode'),
            subtitle: const Text('Stream and download music'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanUtama(),
                ),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.offline_bolt, color: AppTheme.primaryPink),
            title: const Text('Offline Mode'),
            subtitle: const Text('Play downloaded music'),
            onTap: () => Navigator.pop(context),
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
        color: const Color.fromARGB(255, 108, 107, 107).withValues(alpha: 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                    // Implementasi pencarian offline jika diperlukan
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}