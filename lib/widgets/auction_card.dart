import 'package:flutter/material.dart';
import 'package:bookcycle/models/auction.dart';

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const AuctionCard({
    super.key,
    required this.auction,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAuctionInfo(theme),
                  ),
                ],
              ),
              if (actions != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 100,
        color: theme.colorScheme.surfaceVariant,
        child: auction.imageUrl != null
            ? Image.network(
          auction.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
        )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(Icons.menu_book_rounded, size: 40),
    );
  }

  Widget _buildAuctionInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          auction.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (auction.description != null)
          Text(
            auction.description!,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.attach_money_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${auction.currentBid.toStringAsFixed(2)} €',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              auction.isActive ? Icons.timer_outlined : Icons.history,
              size: 16,
              color: auction.isActive
                  ? Colors.orange
                  : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              auction.isActive ? auction.timeLeft : 'Terminée',
              style: TextStyle(
                color: auction.isActive
                    ? Colors.orange
                    : Colors.grey,
              ),
            ),
          ],
        ),
        if (auction.bidderCount != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${auction.bidderCount} participants',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}