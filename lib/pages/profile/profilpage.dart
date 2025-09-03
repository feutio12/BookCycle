import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/loginpage.dart';
import 'profile_components.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, User? user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      }
    }
  }

  Future<void> _updateUserData(Map<String, dynamic> newData) async {
    if (_user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .update(newData);

        // Rafraîchir les données
        _fetchUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Afficher une boîte de dialogue de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Déconnexion de Firebase Auth
        await _auth.signOut();

        // Fermer tous les dialogues et naviguer vers la page de login
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déconnexion réussie'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Fermer les dialogues en cas d'erreur
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController =
    TextEditingController(text: _userData?['name'] ?? '');
    final TextEditingController bioController =
    TextEditingController(text: _userData?['bio'] ?? '');
    final TextEditingController emailController =
    TextEditingController(text: _userData?['email'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modifier le profil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Section pour les préférences
                    _buildPreferencesEditor(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final Map<String, dynamic> updates = {
                      'name': nameController.text,
                      'email': emailController.text,
                      'bio': bioController.text,
                      'preferences': _userData?['preferences'] ?? {},
                      'lastUpdated': FieldValue.serverTimestamp(),
                    };

                    await _updateUserData(updates);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPreferencesEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Préférences:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        // Switch pour les notifications
        Row(
          children: [
            const Text('Notifications'),
            const Spacer(),
            Switch(
              value: _userData?['preferences']?['notifications'] ?? false,
              onChanged: (value) {
                setState(() {
                  _userData ??= {};
                  _userData!['preferences'] ??= {};
                  _userData!['preferences']['notifications'] = value;
                });
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
        // Switch pour les mises à jour par email
        Row(
          children: [
            const Text('Mises à jour par email'),
            const Spacer(),
            Switch(
              value: _userData?['preferences']?['emailUpdates'] ?? false,
              onChanged: (value) {
                setState(() {
                  _userData ??= {};
                  _userData!['preferences'] ??= {};
                  _userData!['preferences']['emailUpdates'] = value;
                });
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
        // Sélecteur de confidentialité
        Row(
          children: [
            const Text('Confidentialité'),
            const Spacer(),
            DropdownButton<String>(
              value: _userData?['preferences']?['privacy'] ?? 'private',
              onChanged: (String? newValue) {
                setState(() {
                  _userData ??= {};
                  _userData!['preferences'] ??= {};
                  _userData!['preferences']['privacy'] = newValue;
                });
              },
              items: <String>['private', 'public']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'private' ? 'Privé' : 'Public'),
                );
              }).toList(),
            ),
          ],
        ),
        // Sélecteur de thème
        Row(
          children: [
            const Text('Thème'),
            const Spacer(),
            DropdownButton<String>(
              value: _userData?['preferences']?['theme'] ?? 'system',
              onChanged: (String? newValue) {
                setState(() {
                  _userData ??= {};
                  _userData!['preferences'] ??= {};
                  _userData!['preferences']['theme'] = newValue;
                });
              },
              items: <String>['system', 'light', 'dark']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value == 'system' ? 'Système' :
                    value == 'light' ? 'Clair' : 'Sombre',
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header avec photo de profil
            ProfileComponents.buildProfileHeader(
                context,
                _userData,
                _showEditProfileDialog
            ),

            // Section d'informations personnelles
            ProfileComponents.buildPersonalInfoSection(_userData),

            // Section des statistiques
            ProfileComponents.buildStatsSection(_userData),

            // Section des préférences
            ProfileComponents.buildPreferencesSection(_userData),

            // Boutons d'action
            ProfileComponents.buildActionButtons(),

            // Bouton de déconnexion
            ProfileComponents.buildLogoutButton(_logout),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}