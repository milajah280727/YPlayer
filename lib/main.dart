import 'package:flutter/material.dart';
import 'package:yplayer/screens/online/beranda.dart';
import 'package:yplayer/screens/online/favorit.dart';
import 'package:yplayer/screens/online/musik.dart';
import 'package:yplayer/screens/online/teratas.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Tambahkan MaterialApp di sini. Ini akan menyelesaikan error Directionality.
    // MaterialApp juga memberikan tema, routing, dan konfigurasi dasar lainnya.
    return MaterialApp(
      title: 'Y Player',
      debugShowCheckedModeBanner: false, // Opsional: untuk menyembunyikan banner debug
      home: const MainTabPage(), // Halaman awal aplikasi adalah widget yang berisi tab
    );
  }
}

// Buat widget terpisah untuk halaman yang berisi tab.
// Ini membuat kode lebih bersih dan terorganisir.
class MainTabPage extends StatelessWidget {
  const MainTabPage({super.key});

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          // Menggunakan 'const' untuk performa yang lebih baik
          leading: const Icon(Icons.menu, color: Colors.white,),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
          actions: const [Icon(Icons.search, color: Colors.white,)],
          title: const Text("Y  P L A Y E R ", style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.pink,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.black,
            tabs: [
              Tab(icon: Icon(Icons.home)),
              Tab(icon: Icon(Icons.music_note)),
              Tab(icon: Icon(Icons.star)),
              Tab(icon: Icon(Icons.trending_up)),
            ],
          ),
        ),
        body:  TabBarView(
          children: [
            BerandaPageOnline(),
            FavoritPageOnline(),
            MusikPageOnline(),
            TeratasPageOnline(),
          ],
        ),
      ),
    );
  }
}