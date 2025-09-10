import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/loginpage.dart';
import 'profile_components.dart';
import 'profile_service.dart';
import 'profile_stats.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, User? user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProfileService _profileService = ProfileService();

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  StreamSubscription? _statsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _currentUser = _auth.currentUser;

    if (_currentUser == null) {
      _redirectToLogin();
      return;
    }

    await _loadUserData();
    _setupStatsListener();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final userData = await _profileService.getUserData(_currentUser!.uid);

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Erreur de chargement: $e');
      }
    }
  }

  void _setupStatsListener() {
    _statsSubscription = _profileService
        .getUserStatsStream(_currentUser!.uid)
        .listen((stats) {
      if (mounted && _userData != null) {
        setState(() {
          _userData!['stats'] = stats;
        });
      }
    }, onError: (error) {
      print('Erreur stream stats: $error');
    });
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  Future<void> _refreshData() async {
    await _profileService.refreshUserStats(_currentUser!.uid);
    await _loadUserData();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoggingOut = true);

      try {
        await _auth.signOut();
        _redirectToLogin();
      } catch (e) {
        setState(() => _isLoggingOut = false);
        _showErrorSnackbar('Erreur de déconnexion: $e');
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userData?['name'] ?? '');
    final bioController = TextEditingController(text: _userData?['bio'] ?? '');
    final preferences = Map<String, dynamic>.from(_userData?['preferences'] ?? {});

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildPreferencesSection(preferences),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _profileService.updateUserProfile(
                  userId: _currentUser!.uid,
                  name: nameController.text,
                  bio: bioController.text,
                );
                Navigator.pop(context);
                _showSuccessSnackbar('Profil mis à jour avec succès');
              } catch (e) {
                _showErrorSnackbar('Erreur de mise à jour: $e');
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(Map<String, dynamic> preferences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Préférences', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Notifications'),
          value: preferences['notifications'] ?? false,
          onChanged: (value) {
            preferences['notifications'] = value;
          },
        ),
        SwitchListTile(
          title: const Text('Mises à jour par email'),
          value: preferences['emailUpdates'] ?? false,
          onChanged: (value) {
            preferences['emailUpdates'] = value;
          },
        ),
      ],
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _profileService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
          ? _buildErrorWidget()
          : _buildProfileContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Erreur de chargement', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadUserData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final stats = _userData?['stats'] ?? {};
    final booksPublished = stats['booksPublished'] ?? 0;
    final auctionsCreated = stats['auctionsCreated'] ?? 0;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // En-tête du profil
            ProfileComponents.buildProfileHeader(
              context,
              _userData,
              _showEditProfileDialog,
            ),

            // Informations personnelles
            ProfileComponents.buildPersonalInfoSection(_userData),

            // Statistiques
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ProfileStats(
                userData: _userData!,
                booksPublishedCount: booksPublished,
                auctionsCount: auctionsCreated,
              ),
            ),

            // Préférences
            ProfileComponents.buildPreferencesSection(_userData),

            // Actions
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