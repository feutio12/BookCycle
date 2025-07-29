import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

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
              decoration: InputDecoration(
                hintText: 'recherche livres, auteurs, par categories...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trending Searches
            const Text(
              '',
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
              children: [
                _buildChip('Romance'),
                _buildChip('Science Fiction'),
                _buildChip('Biographie'),
                _buildChip('Self-Help'),
                _buildChip('Histoire'),
              ],
            ),
            const SizedBox(height: 30),

            // Popular Authors
            const Text(
              'Livres Populaires',
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
                children: [
                  _buildAuthorCard('Feutio\nFred', Icons.person),
                  _buildAuthorCard('Kemgang\nEloge', Icons.person),
                  _buildAuthorCard('Sergio\nRamos', Icons.person),
                  _buildAuthorCard('J.K.\nGabriel', Icons.person),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Recent Searches
            const Text(
              'Vos Recentes Recherches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            Column(
              children: [
                _buildSearchItem('The Silent Patient'),
                _buildSearchItem('Atomic Habits'),
                _buildSearchItem('Educated - Tara Westover'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildAuthorCard(String name, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[50],
            child: Icon(icon, size: 30, color: Colors.blue[700]),
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

  Widget _buildSearchItem(String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, color: Colors.grey),
      title: Text(title),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 20),
        onPressed: () {},
      ),
    );
  }
}