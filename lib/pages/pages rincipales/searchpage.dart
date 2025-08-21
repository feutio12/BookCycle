import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../book/book_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _recentSearches = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  Position? _currentPosition;

  final List<String> _trendingCategories = [
    'Populaires',
    'Récents',
    'Science-fiction',
    'Romance',
    'Fantasy',
    'Classique',
    'Philosophie',
    'Littérature',
  ];

  final List<String> _popularAuthors = [
    'Stephen King',
    'J.K. Rowling',
    'George R.R. Martin',
    'Agatha Christie',
    'Haruki Murakami'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      // Recherche par titre (insensible à la casse)
      final titleResults = await _firestore
          .collection('books')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .get();

      // Recherche par auteur (insensible à la casse)
      final authorResults = await _firestore
          .collection('books')
          .where('author', isGreaterThanOrEqualTo: query)
          .where('author', isLessThan: query + 'z')
          .get();

      // Recherche par catégorie
      final categoryResults = await _firestore
          .collection('books')
          .where('category', isEqualTo: query)
          .get();

      // Combiner tous les résultats
      final allResults = [
        ...titleResults.docs,
        ...authorResults.docs,
        ...categoryResults.docs,
      ];

      // Éliminer les doublons
      final uniqueIds = <String>{};
      final combinedResults = <Map<String, dynamic>>[];

      for (var doc in allResults) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          combinedResults.add({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }

      setState(() {
        _searchResults = combinedResults;
        _isLoading = false;
      });

      // Sauvegarder la recherche récente
      if (combinedResults.isNotEmpty && !_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
        await _saveRecentSearches();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _searchResults.clear();
    });
  }

  void _removeRecentSearch(int index) async {
    setState(() {
      _recentSearches.removeAt(index);
    });
    await _saveRecentSearches();
  }

  void _navigateToBookDetails(Map<String, dynamic> book) async {
    // Ajouter à l'historique
    final title = book['title'] ?? '';
    if (!_recentSearches.contains(title)) {
      setState(() {
        _recentSearches.insert(0, title);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
      await _saveRecentSearches();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          bookId: book['id'],
          book: book,
          publisherId: book['userId'] ?? '',
          publisherName: book['author'] ?? 'Auteur inconnu',
        ),
      ),
    );
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
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher livres, auteurs, catégories...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _isSearching
                      ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _clearSearch,
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  if (value.length > 2) {
                    _performSearch(value);
                  } else if (value.isEmpty) {
                    _clearSearch();
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _performSearch(value);
                  }
                },
              ),
            ),
          ),
        ),
      ),
      body: _isSearching
          ? _buildSearchResults()
          : _buildDiscoverySection(),
    );
  }

  Widget _buildDiscoverySection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catégories tendances
          const Text(
            'Catégories Tendances',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _trendingCategories
                  .map((category) => _buildCategoryChip(category))
                  .toList(),
            ),
          ),
          const SizedBox(height: 30),

          // Auteurs populaires
          const Text(
            'Auteurs Populaires',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _popularAuthors
                  .map((author) => _buildAuthorCard(author))
                  .toList(),
            ),
          ),
          const SizedBox(height: 30),

          // Recherches récentes
          if (_recentSearches.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vos Récentes Recherches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentSearches.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => _buildRecentSearchItem(_recentSearches[index], index),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return _buildShimmerLoader();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun résultat trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Essayez avec d\'autres mots-clés',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final title = book['title'] ?? 'Titre inconnu';
    final author = book['author'] ?? 'Auteur inconnu';
    final imageUrl = book['imageUrl'] ?? '';
    final category = book['category'] ?? '';
    final publisherId = book['userId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToBookDetails(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du livre
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 80,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 100,
                    color: Colors.grey[200],
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.book, color: Colors.grey),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),

              // Informations du livre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Catégorie
                    if (category.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Prix (si disponible)
                    if (book['price'] != null)
                      Text(
                        '${book['price']} €',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 80,
                          height: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: false,
        onSelected: (selected) {
          _searchController.text = label;
          _performSearch(label);
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildAuthorCard(String name) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            _searchController.text = name;
            _performSearch(name);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 25,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String title, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(Icons.history, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
        onPressed: () => _removeRecentSearch(index),
      ),
      onTap: () {
        _searchController.text = title;
        _performSearch(title);
      },
    );
  }
}