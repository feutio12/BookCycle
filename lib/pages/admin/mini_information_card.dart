// mini_information_card.dart
import 'package:bookcycle/pages/admin/responsive.dart';
import 'package:flutter/material.dart';

import 'color_constants.dart';

class MiniInformation extends StatelessWidget {
  final int totalBooks;
  final int totalUsers;
  final int monthlyExchanges;
  final double revenue;

  const MiniInformation({
    Key? key,
    required this.totalBooks,
    required this.totalUsers,
    required this.monthlyExchanges,
    required this.revenue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: Responsive.isMobile(context) ? 1.3 : 1,
      ),
      children: [
        _buildCard(
          context,
          title: "Livres",
          value: totalBooks.toString(),
          icon: Icons.book,
          color: Colors.blue,
        ),
        _buildCard(
          context,
          title: "Utilisateurs",
          value: totalUsers.toString(),
          icon: Icons.people,
          color: Colors.green,
        ),
        _buildCard(
          context,
          title: "Échanges/mois",
          value: monthlyExchanges.toString(),
          icon: Icons.swap_horiz,
          color: Colors.orange,
        ),
        _buildCard(
          context,
          title: "Revenus",
          value: "\$${revenue.toStringAsFixed(2)}",
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
      }) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.more_vert, color: Colors.white54),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}