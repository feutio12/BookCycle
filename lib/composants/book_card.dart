import 'package:flutter/material.dart';

import '../pages/book_detail_page.dart';


class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Function(String) onLikePressed;

  const BookCard({
    super.key,
    required this.book,
    required this.colorScheme,
    required this.textTheme,
    required this.onLikePressed,
  });

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(book: book),

      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(context),
          // Navigation vers la page de détail du livre

        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Couverture du livre
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  book['image'],
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),

              // Détails du livre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            book['title'],
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (book['isPopular'])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Populaire',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.amber[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      book['author'],
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book['description'],
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book['rating'].toString(),
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.category_outlined,
                          color: colorScheme.onSurface.withOpacity(0.5),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book['category'],
                          style: textTheme.bodySmall,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            book['isLiked'] ? Icons.favorite : Icons.favorite_border,
                            color: book['isLiked'] ? colorScheme.error : null,
                          ),
                          onPressed: () => onLikePressed(book['id']),
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book['likes'].toString(),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}