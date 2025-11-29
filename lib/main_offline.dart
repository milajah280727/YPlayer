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

class _HalamanUtamaOfflineState extends State<HalamanUtamaOffline> with 
SingleTickerProviderStateMixin {
  //urang bikin dulu weh fungsi supaya ketika pindah halaman pake TAB nanti si Judul menyesuaikan dengan halaman yang dibuka
  //tab Controller harusnya buat mengkontrol fungsi tab
  late TabController _tabController;

  //ini buat daftar Judul supaya bisa menyesuaikan dengan halaman yang dibuka
  final List<String> _judulTab = ["Beranda", "Playlist",];


  @override
  void initState(){
    super.initState(); 
  _tabController = TabController(length: 2, vsync: this);
  //tambahkan listener buat mendeteksi kalo tabnya berubah
  _tabController.addListener((){
    if(!mounted) return;
    setState(() {
      
    });
  });
  }

  @override
  //dispose supaya tidak ada memory leak
  void dispose(){
    _tabController.dispose();
    super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //styling dulu gengs
        title: Text(_judulTab[_tabController.index]),
        foregroundColor: Colors.white,
        backgroundColor: Colors.pink,
        bottom: TabBar(
          //panggil controllernya coeg sekalian styling
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.black,

          //ini tabnya
          tabs: const[
            Tab(icon: Icon(Icons.home),),
            Tab(icon: Icon(Icons.playlist_add_check),),
        ]),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          children: [
            DrawerHeader(child: Image.asset("assets/images/image.png", width: 10, height: 10,),),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Online Mode"),
              onTap: (){
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HalamanUtama()), (route) => false);
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
      body: TabBarView(
        controller: _tabController,
        children: const[
          BerandaPageOffline(),
          PlaylistPageOffline()
        ],
      ),
    );
  }
}