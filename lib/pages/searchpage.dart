import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Search App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = ['The Silent Patient', 'Atomic Habits', 'Educated - Tara Westover'];
  List<String> _searchResults = [];
  bool _isSearching = false;

  // Données de démonstration
  final List<String> _allBooks = [
    'The Silent Patient',
    'Atomic Habits',
    'Educated - Tara Westover',
    'Dune',
    'The Hobbit',
    '1984',
    'To Kill a Mockingbird',
    'The Great Gatsby'
  ];

  final List<String> _popularAuthors = [
    'Feutio Fred',
    'Kemgang Eloge',
    'Sergio Ramos',
    'J.K. Gabriel'
  ];

  final List<String> _trendingCategories = [
    'Romance',
    'Science Fiction',
    'Biographie',
    'Self-Help',
    'Histoire'
  ];

  void _performSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = _allBooks
            .where((book) => book.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addRecentSearch(String search) {
    if (!_recentSearches.contains(search)) {
      setState(() {
        _recentSearches.insert(0, search);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
    });
  }

  void _removeRecentSearch(int index) {
    setState(() {
      _recentSearches.removeAt(index);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recherche',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'recherche livres, auteurs, par categories...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _isSearching
                    ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: _clearSearch,
                )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              style: const TextStyle(fontSize: 16),
              onChanged: _performSearch,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addRecentSearch(value);
                }
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isSearching
            ? _buildSearchResults()
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trending Searches
            const Text(
              'Catégories Tendances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _trendingCategories
                  .map((category) => _buildChip(category))
                  .toList(),
            ),
            const SizedBox(height: 30),

            // Popular Authors
            const Text(
              'Auteurs Populaires',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _popularAuthors
                    .map((author) => _buildAuthorCard(author))
                    .toList(),
              ),
            ),
            const SizedBox(height: 30),

            // Recent Searches
            const Text(
              'Vos Récentes Recherches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            Column(
              children: List.generate(
                _recentSearches.length,
                    (index) => _buildSearchItem(_recentSearches[index], index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Aucun résultat trouvé',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.book, color: Colors.blue),
          title: Text(_searchResults[index]),
          onTap: () {
            _addRecentSearch(_searchResults[index]);
            // Naviguer vers la page du livre
          },
        );
      },
    );
  }

  Widget _buildChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
      },
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildAuthorCard(String name) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[50],
            child: const Icon(Icons.person, size: 30, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchItem(String title, int index) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, color: Colors.grey),
      title: Text(title),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 20),
        onPressed: () => _removeRecentSearch(index),
      ),
      onTap: () {
        _searchController.text = title;
        _performSearch(title);
      },
    );
  }
}