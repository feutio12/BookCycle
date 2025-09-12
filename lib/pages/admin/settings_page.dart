import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../composants/common_components.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool _notificationsEnabled = true;
  bool _emailReportsEnabled = false;
  String _reportFrequency = 'weekly';

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paramètres administrateur', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildProfileSection(currentUser),
            const SizedBox(height: 32),
            _buildNotificationSettings(),
            const SizedBox(height: 32),
            _buildSystemSettings(),
            const SizedBox(height: 32),
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(User? currentUser) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profil administrateur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryBlue,
                child: Text(currentUser?.email?[0].toUpperCase() ?? 'A', style: const TextStyle(color: Colors.white, fontSize: 20)),
              ),
              title: Text(currentUser?.displayName ?? 'Administrateur', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(currentUser?.email ?? ''),
              trailing: ElevatedButton(
                onPressed: _editProfile,
                child: const Text('Modifier le profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notifications push'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
            SwitchListTile(
              title: const Text('Rapports par email'),
              value: _emailReportsEnabled,
              onChanged: (value) => setState(() => _emailReportsEnabled = value),
            ),
            if (_emailReportsEnabled) ...[
              const SizedBox(height: 16),
              const Text('Fréquence des rapports'),
              DropdownButton<String>(
                value: _reportFrequency,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Quotidien')),
                  DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
                ],
                onChanged: (value) => setState(() => _reportFrequency = value!),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveNotificationSettings,
                child: const Text('Sauvegarder les préférences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuration système', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nom de l\'application'),
                    initialValue: 'BookCycle',
                    validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email de support'),
                    initialValue: 'support@bookcycle.com',
                    validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nombre maximum de livres par utilisateur'),
                    initialValue: '10',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveSystemSettings,
                    child: const Text('Appliquer les changements'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zone dangereuse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 16),
            const Text('Ces actions sont irréversibles. Veuillez être certain de ce que vous faites.', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Supprimer les données de test', style: TextStyle(color: Colors.red)),
                  onPressed: _confirmTestDataDeletion,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.warning, color: Colors.red),
                  label: const Text('Réinitialiser l\'application', style: TextStyle(color: Colors.red)),
                  onPressed: _confirmResetApp,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom d\'affichage'),
                initialValue: _auth.currentUser?.displayName,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                initialValue: _auth.currentUser?.email,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Sauvegarder')),
        ],
      ),
    );
  }

  void _saveNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préférences de notification sauvegardées')),
    );
  }

  void _saveSystemSettings() {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState?.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration système sauvegardée')),
      );
    }
  }

  void _confirmTestDataDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les données de test ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // Implémenter la suppression des données de test
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Données de test supprimées')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmResetApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser l\'application'),
        content: const Text('Cette action supprimera toutes les données. Êtes-vous absolument certain ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // Implémenter la réinitialisation
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Application réinitialisée')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}