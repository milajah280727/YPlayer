import 'package:flutter/material.dart';




class BerandaPageOffline extends StatefulWidget {
  const BerandaPageOffline({super.key});

  @override
  State<BerandaPageOffline> createState() => _BerandaPageOfflineState();
}

class _BerandaPageOfflineState extends State<BerandaPageOffline> with SingleTickerProviderStateMixin{


  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("ini halaman beranda offline"),
    );
  }
  
}