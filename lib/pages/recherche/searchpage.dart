import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'search_content.dart';
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
    'Pablo Picasso',
    'Moliere',
    'Aristote',
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
          publisherName: book['author'] ?? 'Auteur inconnu', publisherEmail: null,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Découvrir',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_currentPosition != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.location_on,
                color: Colors.blue[700],
                size: 24,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher livres, auteurs, catégories...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                  suffixIcon: _isSearching
                      ? IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey[500]),
                    onPressed: _clearSearch,
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildDiscoverySection(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverySection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catégories tendances
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Catégories populaires',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _trendingCategories
                  .map((category) => SearchComponents.buildCategoryChip(
                context,
                category,
                onTap: () {
                  _searchController.text = category;
                  _performSearch(category);
                },
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 32),

          // Auteurs populaires
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Auteurs populaires',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _popularAuthors
                  .map((author) => SearchComponents.buildAuthorCard(
                context,
                author,
                onTap: () {
                  _searchController.text = author;
                  _performSearch(author);
                },
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 32),

          // Recherches récentes
          if (_recentSearches.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Recherches récentes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentSearches.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (context, index) => SearchComponents.buildRecentSearchItem(
                      _recentSearches[index],
                      onTap: () {
                        _searchController.text = _recentSearches[index];
                        _performSearch(_recentSearches[index]);
                      },
                      onRemove: () => _removeRecentSearch(index),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return SearchComponents.buildShimmerLoader();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 70,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              Text(
                'Aucun résultat trouvé',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Text(
                'Essayez avec d\'autres mots-clés',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return SearchComponents.buildBookCard(
          book,
          onTap: () => _navigateToBookDetails(book),
        );
      },
    );
  }
}