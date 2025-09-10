import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileComponents {
  static Widget buildLogoutButton(Function onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        onPressed: () => onTap(),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: const Size(300, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  static Widget buildProfileHeader(
      BuildContext context,
      Map<String, dynamic>? userData,
      Function onEditPressed
      ) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade300,
            Colors.lightBlue,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: userData?['photoURL'] != null
                      ? NetworkImage(userData!['photoURL'])
                      : null,
                  child: userData?['photoURL'] == null
                      ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.blue,
                  )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  userData?['name'] ?? 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  userData?['email'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: ElevatedButton(
              onPressed: () => onEditPressed(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 2),
                  Text('Modifier'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPersonalInfoSection(Map<String, dynamic>? userData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations Personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 15),
              _buildInfoRow('Bio', userData?['bio'] ?? 'Aucune bio fournie'),
              const Divider(),
              _buildInfoRow('Membre depuis', _formatDate(userData?['createdAt'])),
              const Divider(),
              _buildInfoRow('Dernière mise à jour', _formatDate(userData?['lastUpdated'])),
              const Divider(),
              _buildInfoRow('Profil complété',
                  userData?['profileCompleted'] == true ? 'Oui' : 'Non'),
            ],
          ),
        ),
      ),
    );
  }

  // Ajouter cette méthode pour afficher un indicateur de chargement dans les statistiques
  static Widget buildStatsSection(Map<String, dynamic>? userData) {
    final stats = userData?['stats'] ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Livres ajoutés', stats['booksAdded']?.toString() ?? '0'),
                  _buildStatCard('Enchères créées', stats['auctionsCreated']?.toString() ?? '0'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Enchères gagnées', stats['auctionsWon']?.toString() ?? '0'),
                  _buildStatCard('Évaluation', stats['rating']?.toString() ?? '0'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildPreferencesSection(Map<String, dynamic>? userData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Préférences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 15),
              _buildPreferenceItem(
                'Notifications',
                userData?['preferences']?['notifications'] == true ? 'Activées' : 'Désactivées',
                Icons.notifications,
              ),
              const Divider(),
              _buildPreferenceItem(
                'Mises à jour par email',
                userData?['preferences']?['emailUpdates'] == true ? 'Activées' : 'Désactivées',
                Icons.email,
              ),
              const Divider(),
              _buildPreferenceItem(
                'Confidentialité',
                userData?['preferences']?['privacy'] == 'private' ? 'Privé' : 'Public',
                Icons.lock,
              ),
              const Divider(),
              _buildPreferenceItem(
                'Thème',
                userData?['preferences']?['theme'] == 'system' ? 'Système' :
                userData?['preferences']?['theme'] == 'light' ? 'Clair' : 'Sombre',
                Icons.color_lens,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // Naviguer vers la page des livres de l'utilisateur
            },
            icon: const Icon(Icons.book),
            label: const Text('Mes Livres'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,minimumSize: Size(150, 50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              // Naviguer vers la page des enchères de l'utilisateur
            },

            icon: const Icon(Icons.gavel),
            label: const Text('Mes Enchères'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,minimumSize: Size(150, 50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 105),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String title, String value) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  static Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  static Widget _buildPreferenceItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  static String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';

    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    return timestamp.toString();
  }
}