import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Fake categories
  final List<String> _categories = [
    "Music", "Comedy", "Sports", "Gaming", "Travel",
    "Fashion", "Food", "Animals", "Beauty", "Cars"
  ];

  // Fake trending searches
  final List<String> _trending = [
    "Flutter animations",
    "Pakistan cricket",
    "Funny videos",
    "TikTok viral songs",
    "Motivation",
    "AI tools",
  ];

  // Fake search results
  List<Map<String, dynamic>> _videoResults = [];
  bool _isSearching = false;

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _videoResults = List.generate(
        10,
        (index) => {
          "thumbnail": "https://via.placeholder.com/300x500?text=Video+$index",
          "title": "$query Result video $index",
          "views": "${(index + 1) * 1200} views",
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            //  Search Bar
            SliverAppBar(
              backgroundColor: Colors.black,
              pinned: true,
              title: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () => _performSearch(_searchController.text),
                    ),
                  ),
                ),
              ),
            ),

            // If searching → show results
            if (_isSearching) _buildSearchResults()

            else ...[
              //  Trending
              _buildSectionTitle("Trending Searches"),
              _buildTrending(),

              //  Categories
              _buildSectionTitle("Categories"),
              _buildCategories(),
            ],
          ],
        ),
      ),
    );
  }

  //  Trending section
  SliverToBoxAdapter _buildTrending() {
    return SliverToBoxAdapter(
      child: Column(
        children: List.generate(
          _trending.length,
          (index) => ListTile(
            title: Text(
              _trending[index],
              style: const TextStyle(color: Colors.white),
            ),
            leading: const Icon(Icons.trending_up, color: Colors.red),
          ),
        ),
      ),
    );
  }

  //  Categories section
  SliverToBoxAdapter _buildCategories() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories
              .map(
                (cat) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  //  Title builder
  SliverToBoxAdapter _buildSectionTitle(String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 15, top: 18, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  //  Search Results Builder
  SliverToBoxAdapter _buildSearchResults() {
    if (_videoResults.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              "No results found",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: GridView.builder(
        itemCount: _videoResults.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          final video = _videoResults[index];

          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  video["thumbnail"],
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Text(
                    video["views"],
                    style: const TextStyle(
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
