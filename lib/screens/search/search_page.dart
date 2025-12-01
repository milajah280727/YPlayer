import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yplayer/main.dart';
import 'package:yplayer/providers/search_provider.dart';
import 'package:yplayer/screens/search/search_page_result.dart';

class SearchPage extends StatefulWidget {
  // Tambahkan parameter opsional initialQuery
  const SearchPage({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // PERUBAHAN: Isi controller jika initialQuery diberikan
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }

    // Meminta fokus setelah widget dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      Provider.of<SearchProvider>(context, listen: false).addToHistory(query);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchPageResult(query: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.pink,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HalamanUtama()), (route) => false);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 20, color: Colors.white),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: "Cari disini",
            hintStyle: TextStyle(fontSize: 20, color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            _performSearch(value);
          },
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          final history = searchProvider.searchHistory;
          if (history.isEmpty) {
            return const Center(
              child: Text("Tidak ada riwayat pencarian"),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Pencarian Terkini",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        searchProvider.clearHistory();
                      },
                      child: const Text("Hapus Semua"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final query = history[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(query),
                      onTap: () => _performSearch(query),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Provider.of<SearchProvider>(context, listen: false).removeFromHistory(query);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}