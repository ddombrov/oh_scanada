import 'package:flutter/material.dart';
import '../widgets/screen_layout.dart';
import '../widgets/page_section.dart';
import '../colours/colour_system.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  List<String> _searchHistory = [];
  bool _showHistory = false;
  bool _isSearchingProducts = true;
  bool _showTrending = true;

  void _performSearch(String query) {
    setState(() {
      _searchResults =
          List.generate(5, (index) => '$query Result ${index + 1}');
      _searchHistory.insert(0, query);
      _showTrending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('SearchScreen build called'); 

    return ScreenLayout(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _isSearchingProducts
                              ? 'Search Products'
                              : 'Search Companies',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        onSubmitted: (value) {
                          _performSearch(value);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults.clear();
                          _showTrending = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () {
                        setState(() {
                          _showHistory = !_showHistory;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Products/Companies Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSearchingProducts = true;
                          _searchResults.clear();
                          _showTrending = true;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _isSearchingProducts
                            ? CanadianTheme.canadianRed
                            : Colors.grey,
                      ),
                      child: const Text('Products'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSearchingProducts = false;
                          _searchResults.clear();
                          _showTrending = true;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: !_isSearchingProducts
                            ? CanadianTheme.canadianRed
                            : Colors.grey,
                      ),
                      child: const Text('Companies'),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Search History or Trending Products
                if (_showHistory && _searchHistory.isNotEmpty)
                  buildSection(
                    title: 'Recent Searches',
                    icon: Icons.history,
                    child: Column(
                      children: _searchHistory
                          .map((query) => ListTile(
                                title: Text(query),
                                onTap: () {
                                  _performSearch(query);
                                  setState(() {
                                    _showHistory = false;
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  )
                else if (_showHistory && _searchHistory.isEmpty)
                  buildSection(
                    title: 'Recent Searches',
                    icon: Icons.history,
                    child: const Text('No recent searches'),
                  )
                else if (_showTrending)
                  buildSection(
                    title:
                        'Trending ${_isSearchingProducts ? 'Products' : 'Companies'}',
                    icon: Icons.trending_up,
                    child: Column(
                      children: const [
                        ListTile(title: Text('Trending Item 1')),
                        ListTile(title: Text('Trending Item 2')),
                        ListTile(title: Text('Trending Item 3')),
                      ],
                    ),
                  ),

                // Search Results
                if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_searchResults[index]),
                          onTap: () {
                            Navigator.pushNamed(context, '/product_info');
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
