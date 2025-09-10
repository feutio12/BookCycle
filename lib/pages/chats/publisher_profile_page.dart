import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../composants/common_components.dart';
import 'chat_service.dart';

class PublisherProfilePage extends StatelessWidget {
  final String publisherId;
  final String publisherName;

  const PublisherProfilePage({
    super.key,
    required this.publisherId,
    required this.publisherName,
  });

  Future<Map<String, dynamic>?> _getPublisherData() async {
    return await ChatService.getUserProfile(publisherId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil de $publisherName')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getPublisherData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Erreur de chargement du profil'));
          }

          final publisherData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      publisherName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    publisherName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 24),
                if (publisherData['bio'] != null)
                  Text(
                    publisherData['bio'],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                const SizedBox(height: 16),
                _buildInfoItem('Email', publisherData['email'] ?? 'Non disponible'),
                _buildInfoItem('Membre depuis',
                    _formatDate(publisherData['createdAt'])),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Envoyer un message',
                  onPressed: () {
                    Navigator.pop(context); // Retour à la discussion
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';

    try {
      final date = timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}