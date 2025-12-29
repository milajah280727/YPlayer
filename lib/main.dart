import 'package:audio_service/audio_service.dart';
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
import 'package:yplayer/services/audio_player_service.dart';
import 'package:yplayer/services/download_service.dart';
import 'package:yplayer/widgets/mini_player_widget.dart';
import 'package:yplayer/main_offline.dart';

// 1. Jalankan App() langsung, tidak ada await di sini
void main() {
  runApp(const App());
}

// 2. App Widget menangani inisialisasi AudioService
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Variabel untuk menyimpan proses async
  late Future<AudioPlayerHandler> _initAudioServiceFuture;
  // Simpan handler untuk diakses saat dispose
  AudioPlayerHandler? _audioHandler;

  @override
  void initState() {
    super.initState();
    // Inisialisasi AudioService tapi tidak memblokir UI
    _initAudioServiceFuture = _initAudioService();
  }

  Future<AudioPlayerHandler> _initAudioService() async {
    // PERBAIKAN 1: Gunakan nama icon 'launcher_icon' sesuai Manifest kamu sebelumnya
    return await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.yourapp.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        // Pastikan nama icon ini cocok dengan folder res/mipmap kamu
        androidNotificationIcon: 'mipmap/launcher_icon', 
      ),
    );
  }

  @override
  void dispose() {
    _audioHandler?.stop(); // Hentikan handler saat app ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AudioPlayerHandler>(
      future: _initAudioServiceFuture,
      builder: (context, snapshot) {
        // Tampilkan Loading Screen saat menunggu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Colors.pink),
                    SizedBox(height: 20),
                    Text(
                      "Menyiapkan Audio...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Jika Error
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            ),
          );
        }

        // Jika Sukses, Jalankan Aplikasi Utama dengan Provider
        _audioHandler = snapshot.data!;

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => SearchProvider()),
            ChangeNotifierProvider(
              create: (context) => PlayerProvider(audioHandler: _audioHandler!),
            ),
          ],
          child: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YPlayer',
      // Pastikan AppTheme.darkTheme sudah terdefinisi di file app_theme.dart
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
      // Menggunakan withValues(alpha: ...) untuk menghindari warning deprecated
      backgroundColor: Colors.white.withValues(alpha: 0.3),
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
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                Image.asset("assets/images/onlineimage.png", width: 80, height: 80),
                const SizedBox(height: 5),
                const Text("YPlayer"),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wifi, color: Colors.pink),
            title: const Text('Online Mode'),
            subtitle: const Text('Stream and download music'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.offline_bolt, color: Colors.grey),
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
                color: Colors.grey[600],
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
            color: const Color.fromARGB(255, 79, 78, 78).withValues(alpha: 0.1),
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