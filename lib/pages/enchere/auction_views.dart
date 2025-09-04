import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/models/auction.dart';
import 'package:intl/intl.dart';
import '../../composants/auction_components.dart';
import '../../composants/common_components.dart';

class AuctionViews {
  static Widget buildOngletEncheres(
      BuildContext context,
      Stream<QuerySnapshot> streamEncheres,
      bool estActif,
      bool estConnecte,
      Function chargerEncheres,
      Function afficherDetailsEnchere,
      Function placerOffre,
      Function afficherMessageConnexion
      ) {
    return StreamBuilder<QuerySnapshot>(
      stream: streamEncheres,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: ErrorMessage(
              message: 'Erreur: ${snapshot.error}',
              onRetry: () => chargerEncheres(),
            ),
          );
        }

        final encheres = snapshot.data?.docs.map((doc) => Enchere.fromFirestore(doc)).toList() ?? [];

        if (encheres.isEmpty) {
          return Center(
            child: EmptyState(
              icon: estActif ? Icons.hourglass_empty : Icons.history_toggle_off,
              message: estActif ? 'Aucune enchère en cours' : 'Aucune enchère terminée',
              subtitle: estActif && !estConnecte
                  ? 'Connectez-vous pour créer la première enchère !'
                  : null,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => chargerEncheres(),
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: encheres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final enchere = encheres[index];
              return AuctionCard(
                enchere: enchere,
                onTap: () => afficherDetailsEnchere(enchere),
                imageUrl: enchere.imageUrl,
                actions: [
                  if (estActif && enchere.estActive)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (!estConnecte) {
                          afficherMessageConnexion('placer une offre');
                        } else {
                          placerOffre(enchere);
                        }
                      },
                      child: const Text('Enchérir', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  TextButton(
                    onPressed: () => afficherDetailsEnchere(enchere),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text('Détails'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static Widget buildDetailsEnchere(
      BuildContext context,
      Enchere enchere,
      bool estConnecte,
      Function placerOffre,
      Function afficherMessageConnexion
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Center(
            child: Hero(
              tag: 'enchere-${enchere.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(enchere.imageUrl),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(enchere.titre,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface
              )
          ),
          const SizedBox(height: 12),
          if (enchere.description != null)
            Text(enchere.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                )
            ),
          const SizedBox(height: 24),
          Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          const SizedBox(height: 16),
          _buildDetailItem(
            context,
            icon: Icons.attach_money,
            label: 'Prix ${enchere.estActive ? 'actuel' : 'final'}',
            value: '${enchere.prixActuel.toStringAsFixed(2)} fcfa',
          ),
          if (enchere.prixDepart != null)
            _buildDetailItem(
              context,
              icon: Icons.price_change,
              label: 'Prix de départ',
              value: '${enchere.prixDepart!.toStringAsFixed(2)} fcfa',
            ),
          _buildDetailItem(
            context,
            icon: enchere.estActive ? Icons.timer : Icons.history,
            label: enchere.estActive ? 'Temps restant' : 'Statut',
            value: enchere.estActive
                ? _formaterTempsRestant(enchere.dateFin)
                : 'Terminée le ${DateFormat('dd/MM/yyyy').format(enchere.dateFin)}',
          ),
          if (enchere.etatLivre != null)
            _buildDetailItem(
              context,
              icon: Icons.star,
              label: 'État du livre',
              value: enchere.etatLivre!,
            ),
          if (!enchere.estActive && enchere.gagnant != null)
            _buildDetailItem(
              context,
              icon: Icons.emoji_events,
              label: 'Gagnant',
              value: enchere.gagnant!,
            ),
          if (!estConnecte && enchere.estActive) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Connectez-vous pour placer une offre',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                child: const Text('Fermer'),
              ),
              if (enchere.estActive) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (!estConnecte) {
                      Navigator.pop(context);
                      afficherMessageConnexion('placer une offre');
                    } else {
                      placerOffre(enchere);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Faire une offre', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _buildDetailItem(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            )),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static String _formaterTempsRestant(DateTime dateFin) {
    final difference = dateFin.difference(DateTime.now());
    if (difference.inDays > 0) return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    if (difference.inHours > 0) return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    return 'Moins d\'une minute';
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;
  final Function onRetry;

  const ErrorMessage({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error
          ),
          const SizedBox(height: 16),
          Text(message,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => onRetry(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}