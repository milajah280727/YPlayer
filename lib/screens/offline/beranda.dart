import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



class BerandaPageOffline extends StatefulWidget {
  const BerandaPageOffline({super.key});

  @override
  State<BerandaPageOffline> createState() => _BerandaPageOfflineState();
}

class _BerandaPageOfflineState extends State<BerandaPageOffline> with SingleTickerProviderStateMixin{

  late TabController _tabController;

  //ini buat daftar Judul supaya bisa menyesuaikan dengan halaman yang dibuka
  final List<String> _judulTab = ["Beranda", "Musik", "Favorit", "Teratas"];

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("ini halaman beranda offline"),
    );
  }
  
}