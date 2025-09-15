import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_service.dart';

class AuctionCompletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Vérifier et traiter les enchères terminées
  Future<void> checkCompletedAuctions() async {
    final now = DateTime.now();
    final completedAuctions = await _firestore
        .collection('encheres')
        .where('dateFin', isLessThan: now)
        .where('statut', isEqualTo: 'active')
        .get();

    for (var auctionDoc in completedAuctions.docs) {
      await _processCompletedAuction(auctionDoc);
    }
  }

  Future<void> _processCompletedAuction(QueryDocumentSnapshot auctionDoc) async {
    final auctionData = auctionDoc.data() as Map<String, dynamic>;
    final auctionId = auctionDoc.id;

    // Marquer l'enchère comme terminée
    await _firestore.collection('encheres').doc(auctionId).update({
      'statut': 'completed',
      'gagnant': auctionData['dernierEncherisseur'],
    });

    // Récupérer toutes les offres pour cette enchère
    final offers = await _firestore
        .collection('encheres')
        .doc(auctionId)
        .collection('offres')
        .orderBy('montant', descending: true)
        .get();

    if (offers.docs.isNotEmpty) {
      // La première offre est la gagnante (la plus élevée)
      final winningOffer = offers.docs.first;
      final winningOfferData = winningOffer.data() as Map<String, dynamic>;

      // Capturer le paiement du gagnant
      if (winningOfferData['paymentIntentId'] != null) {
        await PaymentService.capturePayment(winningOfferData['paymentIntentId']);

        // Mettre à jour le statut de l'offre gagnante
        await winningOffer.reference.update({
          'paymentStatus': 'captured'
        });

        // Notifier le créateur de l'enchère
        await _notifyAuctionCreator(auctionData, winningOfferData);
      }

      // Rembourser tous les autres participants
      for (var offer in offers.docs.skip(1)) {
        final offerData = offer.data() as Map<String, dynamic>;
        if (offerData['paymentIntentId'] != null) {
          await PaymentService.refundPayment(offerData['paymentIntentId']);

          // Mettre à jour le statut de l'offre
          await offer.reference.update({
            'paymentStatus': 'refunded'
          });

          // Notifier l'utilisateur remboursé
          await _notifyRefundedUser(offerData);
        }
      }
    }
  }

  Future<void> _notifyAuctionCreator(Map<String, dynamic> auctionData, Map<String, dynamic> winningOfferData) async {
    // Envoyer une notification au créateur de l'enchère
    await _firestore.collection('notifications').add({
      'userId': auctionData['createurId'],
      'title': 'Votre enchère a été remportée',
      'message': 'L\'enchère "${auctionData['titre']}" a été remportée pour ${winningOfferData['montant']} FCFA',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> _notifyRefundedUser(Map<String, dynamic> offerData) async {
    // Envoyer une notification à l'utilisateur remboursé
    await _firestore.collection('notifications').add({
      'userId': offerData['userId'],
      'title': 'Remboursement effectué',
      'message': 'Votre offre de ${offerData['montant']} FCFA a été remboursée',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}