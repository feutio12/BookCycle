import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';
import 'package:flutter/rendering.dart';

import '../../composants/common_components.dart';
import '../../composants/common_utils.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, User? user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookCycle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentGreen,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user != null) {
              return UserProfileScreen(user: user);
            }
            return Scaffold(
              body: Center(
                child: InfoMessage(
                  message: 'Vous n\'êtes pas encore connecté',
                  icon: Icons.person_outline,
                  color: AppColors.primaryBlue,
                ),
              ),
            );
          }
          return const Scaffold(
            body: LoadingIndicator(message: 'Chargement...'),
          );
        },
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  final User user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_showAppBarTitle) {
        setState(() => _showAppBarTitle = true);
      } else if (_scrollController.offset <= 100 && _showAppBarTitle) {
        setState(() => _showAppBarTitle = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (!doc.exists) {
        await _createDefaultUserDocument();
      } else {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      AppUtils.showErrorSnackBar(context, 'Erreur de chargement: ${e.toString()}');
    }
  }

  Future<void> _createDefaultUserDocument() async {
    try {
      final newUser = {
        'name': widget.user.displayName,
        'email': widget.user.email,
        'memberSince': Timestamp.now(),
        'bio': 'Nouvel utilisateur sur BookCycle!',
        'booksShared': 0,
        'booksReceived': 0,
        'rating': 0.0,
        'profileCompleted': false,
        'preferences': {
          'notifications': true,
          'emailUpdates': true,
          'privacy': 'public',
          'theme': 'system'
        }
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(newUser);

      setState(() {
        userData = newUser;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      AppUtils.showErrorSnackBar(context, 'Erreur de création: ${e.toString()}');
    }
  }

  Future<void> _signOut() async {
    try {
      // Déconnexion technique de Firebase
      await FirebaseAuth.instance.signOut();

      // Redirection vers la page de connexion sans possibilité de retour
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false, // Supprime toutes les routes précédentes
      );

    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erreur de déconnexion: ${e.toString()}');
    }
  }

  // Méthode pour afficher la boîte de dialogue de confirmation
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Fermer la boîte de dialogue
              _signOut(); // Exécuter la déconnexion
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  // Fonction pour modifier le profil
  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: userData!['name']);
    final bioController = TextEditingController(text: userData!['bio']);

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  controller: bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({
          'name': nameController.text,
          'bio': bioController.text,
          'profileCompleted': true,
        });

        // Mettre à jour les données locales
        setState(() {
          userData!['name'] = nameController.text;
          userData!['bio'] = bioController.text;
          userData!['profileCompleted'] = true;
        });

        AppUtils.showSuccessSnackBar(context, 'Profil mis à jour avec succès!');
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erreur de mise à jour: ${e.toString()}');
      }
    }
  }

  // Fonction pour modifier les préférences
  Future<void> _editPreferences() async {
    // Récupérer les préférences actuelles ou utiliser des valeurs par défaut
    final preferences = userData!['preferences'] ?? {
      'notifications': true,
      'emailUpdates': true,
      'privacy': 'public',
      'theme': 'system'
    };

    bool notifications = preferences['notifications'] ?? true;
    bool emailUpdates = preferences['emailUpdates'] ?? true;
    String privacy = preferences['privacy'] ?? 'public';
    String theme = preferences['theme'] ?? 'system';

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Préférences'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Notifications'),
                      value: notifications,
                      onChanged: (value) {
                        setState(() {
                          notifications = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mises à jour par email'),
                      value: emailUpdates,
                      onChanged: (value) {
                        setState(() {
                          emailUpdates = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Confidentialité:'),
                    RadioListTile<String>(
                      title: const Text('Public'),
                      value: 'public',
                      groupValue: privacy,
                      onChanged: (value) {
                        setState(() {
                          privacy = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Privé'),
                      value: 'private',
                      groupValue: privacy,
                      onChanged: (value) {
                        setState(() {
                          privacy = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Thème:'),
                    DropdownButtonFormField<String>(
                      value: theme,
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('Système')),
                        DropdownMenuItem(value: 'light', child: Text('Clair')),
                        DropdownMenuItem(value: 'dark', child: Text('Sombre')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          theme = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({
          'preferences': {
            'notifications': notifications,
            'emailUpdates': emailUpdates,
            'privacy': privacy,
            'theme': theme
          }
        });

        // Mettre à jour les données locales
        setState(() {
          userData!['preferences'] = {
            'notifications': notifications,
            'emailUpdates': emailUpdates,
            'privacy': privacy,
            'theme': theme
          };
        });

        AppUtils.showSuccessSnackBar(context, 'Préférences mises à jour avec succès!');
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erreur de mise à jour: ${e.toString()}');
      }
    }
  }

  // Fonction pour modifier la photo de profil
  Future<void> _editProfilePhoto() async {
    // Dans une implémentation réelle, vous utiliseriez image_picker
    // Pour cet exemple, nous allons simplement montrer une démo
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier la photo de profil'),
          content: const Text('Cette fonctionnalité sera bientôt disponible!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userData == null) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Chargement du profil...'),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _showAppBarTitle
            ? AppColors.primaryBlue.withOpacity(0.9)
            : Colors.transparent,
        elevation: _showAppBarTitle ? 4 : 0,
        title: AnimatedOpacity(
          opacity: _showAppBarTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text('Profil de ${userData!['name']}'),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showSignOutDialog,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
              collapseMode: CollapseMode.parallax,
            ),
            automaticallyImplyLeading: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildUserStats(),
                  const SizedBox(height: 24),
                  _buildProfileSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 70),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: widget.user.photoURL != null
                      ? NetworkImage(widget.user.photoURL!)
                      : null,
                  child: widget.user.photoURL == null
                      ? const Icon(Icons.person,
                      size: 50,
                      color: Colors.white)
                      : null,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: AppColors.primaryBlue,
                  onPressed: _editProfilePhoto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userData!['name'] ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userData!['email'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Membre depuis ${_formatDate(userData!['memberSince'])}',
            style: const TextStyle(
                fontSize: 14,
                color: Colors.white70
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Publications',
              userData!['booksShared'].toString(),
              Icons.post_add_rounded,
              AppColors.accentGreen,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              'Reçus',
              userData!['booksReceived'].toString(),
              Icons.book,
              AppColors.primaryBlue,
            ),
            _buildVerticalDivider(),
            _buildStatItem(
              'Note',
              (userData!['rating'] ?? 0.0).toStringAsFixed(1), // Correction ici
              Icons.star,
              Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'À propos',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _editProfile,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              userData!['bio'] ?? '',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Modifier le profil'),
            onPressed: _editProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Préférences'),
            onPressed: _editPreferences,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'date inconnue';
  }
}