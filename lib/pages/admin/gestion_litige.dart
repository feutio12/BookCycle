import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DisputePage extends StatefulWidget {
  const DisputePage({super.key});

  @override
  State<DisputePage> createState() => _DisputePageState();
}

class _DisputePageState extends State<DisputePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Litiges BookCycle'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('disputes')
            .where('resolved', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final dispute = snapshot.data!.docs[index];
              final data = dispute.data() as Map<String, dynamic>;

              return ExpansionTile(
                title: Text('Litige #${dispute.id.substring(0, 5)}'),
                subtitle: Text('Livre: ${data['bookTitle']}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${data['type']}'),
                        Text('Créé le: ${DateFormat('dd/MM/yyyy').format(data['createdAt'].toDate())}'),
                        const SizedBox(height: 8),
                        const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(data['description']),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _resolveDispute(dispute.id, false),
                              child: const Text('Rejeter'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _resolveDispute(dispute.id, true),
                              child: const Text('Résoudre'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _resolveDispute(String disputeId, bool resolved) async {
    await _firestore.collection('disputes').doc(disputeId).update({
      'resolved': true,
      'resolutionStatus': resolved ? 'resolved' : 'rejected',
      'resolvedAt': DateTime.now(),
    });
  }
}