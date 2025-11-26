import 'package:flutter/material.dart';
import 'package:yplayer/main_offline.dart';

//screens
import 'package:yplayer/screens/online/beranda.dart';
import 'package:yplayer/screens/online/favorit.dart';
import 'package:yplayer/screens/online/musik.dart';
import 'package:yplayer/screens/online/teratas.dart';
import 'package:yplayer/screens/search/search_page.dart';



void main() {
  runApp(const MyApp());
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


//halaman utama
class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> with 
SingleTickerProviderStateMixin {
  //urang bikin dulu weh fungsi supaya ketika pindah halaman pake TAB nanti si Judul menyesuaikan dengan halaman yang dibuka
  //tab Controller harusnya buat mengkontrol fungsi tab
  late TabController _tabController;

  //ini buat daftar Judul supaya bisa menyesuaikan dengan halaman yang dibuka
  final List<String> _judulTab = ["Beranda", "Musik", "Favorit", "Teratas"];


  @override
  void initState(){
    super.initState(); 
  _tabController = TabController(length: 4, vsync: this);
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
        
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
        actions:  [IconButton(onPressed: () { 
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage()));
         },icon: Icon(Icons.search),)],
        bottom: TabBar(
          //panggil controllernya coeg sekalian styling
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.black,

          //ini tabnya
          tabs: const[
            Tab(icon: Icon(Icons.home),),
            Tab(icon: Icon(Icons.music_note),),
            Tab(icon: Icon(Icons.star),),
            Tab(icon: Icon(Icons.trending_up),),
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Offline Mode"),
              onTap: (){
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => HalamanUtamaOffline()));
              },
            )
          ],
          
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const[
          BerandaPageOnline(),
          MusikPageOnline(),
          FavoritPageOnline(),
          TeratasPageOnline(),
        ],
      ),
    );
  }
}