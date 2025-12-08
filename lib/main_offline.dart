import 'package:flutter/material.dart';
import 'package:yplayer/main.dart';
import 'package:yplayer/screens/offline/beranda.dart';

//screens
import 'package:yplayer/screens/offline/playlist_page_offline.dart';

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

class _HalamanUtamaOfflineState extends State<HalamanUtamaOffline> {
  // 当前选中的页面索引
  int _currentIndex = 0;
  
  // 页面标题列表
  final List<String> _judulTab = ["Beranda", "Playlist"];
  
  // 页面列表
  final List<Widget> _pages = [
    const BerandaPageOffline(),
    const PlaylistPageOffline()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 根据当前选中的页面索引显示标题
        title: Text(_judulTab[_currentIndex]),
        foregroundColor: Colors.white,
        backgroundColor: Colors.pink,
      ),
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
                  MaterialPageRoute(builder: (context) => HalamanUtama()), 
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
      // 使用IndexedStack来管理页面切换
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // 底部导航栏
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add_check),
            label: 'Playlist',
          ),
        ],
      ),
    );
  }
}