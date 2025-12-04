import 'package:flutter/material.dart';




class BerandaPageOffline extends StatefulWidget {
  const BerandaPageOffline({super.key});

  @override
  State<BerandaPageOffline> createState() => _BerandaPageOfflineState();
}

class _BerandaPageOfflineState extends State<BerandaPageOffline> with SingleTickerProviderStateMixin{
@override
  Widget build(BuildContext context) {
    // HAPUS Scaffold, langsung kembalikan widget utamanya
    return const Center(
      child: Text("Ini halaman playlist offline"),
    );
  }
}