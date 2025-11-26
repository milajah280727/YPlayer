import 'package:flutter/material.dart';


class PlaylistPageOffline extends StatefulWidget {
  const PlaylistPageOffline({super.key});

  @override
  State<PlaylistPageOffline> createState() => _PlaylistPageOfflineState();
}

class _PlaylistPageOfflineState extends State<PlaylistPageOffline> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Ini halmaan pllaylist offline"),
    );
  }
}