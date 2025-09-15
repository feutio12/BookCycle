import 'package:flutter/material.dart';
import 'card_details.dart'; // Ajoutez cette importation

class PaymentDialog extends StatefulWidget {
  final String clientSecret;
  final double amount;

  const PaymentDialog({super.key, required this.clientSecret, required this.amount});

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paiement sécurisé'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Montant: ${widget.amount.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de carte',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un numéro de carte';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'MM/AA',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date requise';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvcController,
                    decoration: const InputDecoration(
                      labelText: 'CVC',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CVC requis';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final expDate = _expiryController.text.split('/');
              final cardDetails = CardDetails( // Utilisez directement CardDetails
                number: _cardNumberController.text,
                expMonth: int.parse(expDate[0]),
                expYear: int.parse(expDate[1]),
                cvc: _cvcController.text,
              );
              Navigator.pop(context, cardDetails);
            }
          },
          child: const Text('Payer'),
        ),
      ],
    );
  }
}