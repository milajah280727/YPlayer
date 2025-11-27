import 'package:flutter/material.dart';
import 'package:yplayer/main.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});


  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.pink,
        automaticallyImplyLeading: false,
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => HalamanUtama()));
        }, icon: Icon(Icons.arrow_back)),
        actions: [IconButton(onPressed: (){
        }, icon: Icon(Icons.search))],
        title: TextField(
          style: TextStyle(
            fontSize: 20,
            color: Colors.white
          ),
          decoration: InputDecoration(
            hintText: "Cari disini",
            hintStyle: TextStyle(
              fontSize: 20,
              color: Colors.white
            ),
            border: InputBorder.none
          ),
        ),
      ),
      body: Padding(padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 1)),
    );
  }
}