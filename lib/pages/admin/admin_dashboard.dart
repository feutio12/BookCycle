import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../composants/common_components.dart';
import 'dashboard_overview.dart';
import 'user_management_page.dart';
import 'book_management_page.dart';
import 'auction_management_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSidebarCollapsed = false;
  String _adminName = "Administrateur";

  final List<Widget> _adminPages = [
    const DashboardOverview(),
    const UserManagementPage(),
    const BookManagementPage(),
    const AuctionManagementPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  final List<String> _pageTitles = [
    'Tableau de bord',
    'Gestion des utilisateurs',
    'Gestion des livres',
    'Gestion des enchères',
    'Rapports et statistiques',
    'Paramètres administrateur'
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _adminName = userDoc.data()?['name'] ?? 'Administrateur';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 80 : 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildSidebar(),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: _isSidebarCollapsed
                    ? BorderRadius.zero
                    : const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // En-tête de page
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          _pageTitles[_selectedIndex],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const Spacer(),
                        // Indicateur de statut de connexion
                        StreamBuilder<DocumentSnapshot>(
                            stream: _firestore.collection('server').doc('status').snapshots(),
                            builder: (context, snapshot) {
                              final isOnline = snapshot.data?.data() != null
                                  ? (snapshot.data!.data() as Map<String, dynamic>)['status'] == 'online'
                                  : true;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: isOnline ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: isOnline ? Colors.green : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isOnline ? 'En ligne' : 'Hors ligne',
                                      style: TextStyle(
                                        color: isOnline ? Colors.green : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                        ),
                        const SizedBox(width: 16),
                        // Notification bell avec badge
                        StreamBuilder<QuerySnapshot>(
                            stream: _firestore.collection('notifications')
                                .where('read', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

                              return Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_none, color: Colors.grey, size: 28),
                                    onPressed: () {
                                      _showNotifications(context);
                                    },
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                ],
                              );
                            }
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _adminPages[_selectedIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings,
                  color: Colors.white,
                  size: _isSidebarCollapsed ? 28 : 32),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'BookCycle Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
              IconButton(
                icon: Icon(
                  _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildNavItem(Icons.dashboard, 'Tableau de bord', 0),
              _buildNavItem(Icons.people, 'Utilisateurs', 1),
              _buildNavItem(Icons.book, 'Livres', 2),
              _buildNavItem(Icons.gavel, 'Enchères', 3),
              _buildNavItem(Icons.analytics, 'Rapports', 4),
              _buildNavItem(Icons.settings, 'Paramètres', 5),
              const Divider(),
              _buildNavItem(Icons.exit_to_app, 'Déconnexion', 6),
            ],
          ),
        ),
        _buildUserInfo(),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Tooltip(
      message: _isSidebarCollapsed ? title : '',
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? AppColors.primaryBlue : Colors.grey[700],
            size: 22),
        title: _isSidebarCollapsed
            ? null
            : Text(title, style: TextStyle(
          color: isSelected ? AppColors.primaryBlue : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        )),
        minLeadingWidth: 10,
        contentPadding: _isSidebarCollapsed
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: isSelected
            ? AppColors.primaryBlue.withOpacity(0.1)
            : Colors.transparent,
        selected: isSelected,
        onTap: () => _handleNavigation(index),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == 6) {
      _showLogoutConfirmation();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion', style: TextStyle(color: AppColors.primaryBlue)),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('notifications')
                      .orderBy('timestamp', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('Aucune notification'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final notification = snapshot.data!.docs[index];
                        final data = notification.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: Icon(
                            _getNotificationIcon(data['type']),
                            color: AppColors.primaryBlue,
                          ),
                          title: Text(data['title'] ?? 'Notification'),
                          subtitle: Text(data['message'] ?? ''),
                          trailing: Text(
                            _formatTimestamp(data['timestamp']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () {
                            // Marquer comme lu
                            _firestore.collection('notifications')
                                .doc(notification.id)
                                .update({'read': true});
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'warning': return Icons.warning;
      case 'info': return Icons.info;
      case 'error': return Icons.error;
      case 'success': return Icons.check_circle;
      default: return Icons.notifications;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Le ${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildUserInfo() {
    final currentUser = _auth.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = 5; // Redirige vers les paramètres
          });
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: _isSidebarCollapsed ? 18 : 20,
              backgroundColor: AppColors.primaryBlue,
              child: currentUser?.email != null
                  ? Text(
                currentUser!.email![0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isSidebarCollapsed ? 14 : 16,
                ),
              )
                  : Icon(Icons.person,
                  color: Colors.white,
                  size: _isSidebarCollapsed ? 18 : 20),
            ),
            if (!_isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _adminName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}