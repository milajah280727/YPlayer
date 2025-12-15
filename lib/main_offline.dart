import 'package:flutter/material.dart';
import 'package:yplayer/main.dart'; // Impor HalamanUtama dari main.dart
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
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HalamanUtamaOffline(),
    );
  }
}

//halaman utama
class HalamanUtamaOffline extends StatefulWidget {
  const HalamanUtamaOffline({super.key});

  @override
  State<HalamanUtamaOffline> createState() => _HalamanUtamaOfflineState();
}

class _HalamanUtamaOfflineState extends State<HalamanUtamaOffline>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _judulTab = ["Beranda", "Playlist"];
  
  // Tambahkan GlobalKey untuk Scaffold
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
    // Ambil padding untuk menghindari area sistem
    final padding = MediaQuery.of(context).padding;
    
    return Scaffold(
      // Tambahkan key ke Scaffold
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          children: [
            DrawerHeader(
              child: Image.asset(
                "assets/images/image.png", 
                width: 10, 
                height: 10,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Online Mode"),
              onTap: (){
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (context) => const HalamanUtama()), 
                  (route) => false
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Offline Mode"),
              onTap: (){
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCustomAppBar(context, padding),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: padding.bottom),
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      BerandaPageOffline(),
                      PlaylistPageOffline(),
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

  Widget _buildCustomAppBar(BuildContext context, EdgeInsets padding) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.pink,
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
                  icon: const Icon(Icons.menu, color: Colors.white),
                  // Gunakan GlobalKey untuk membuka drawer
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Text(
                  _judulTab[_tabController.index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    // Tambahkan fungsi pencarian jika diperlukan
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => const SearchPage()),
                    // );
                  },
                ),
              ],
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(icon: Icon(Icons.home)),
                Tab(icon: Icon(Icons.playlist_add_check)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}