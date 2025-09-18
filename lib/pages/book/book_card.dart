import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../chats/chat_service.dart';
import '../chats/chatpage.dart';
import 'book_details_modal.dart'; // Nouveau fichier pour le modal

class BookCard extends StatefulWidget {
  final Map<String, dynamic> book;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Function(String) onLikePressed;
  final String currentUserId;
  final Function(String) onDeleteBook;
  final Function(Map<String, dynamic>) onEditBook;
  final Function() onContactPublisher;

  const BookCard({
    super.key,
    required this.book,
    required this.colorScheme,
    required this.textTheme,
    required this.onLikePressed,
    required this.currentUserId,
    required this.onDeleteBook,
    required this.onEditBook,
    required this.onContactPublisher,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isHovered = false;
  bool _isLiked = false;
  Timer? _likeDebounce;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.book['isLiked'] ?? false;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _likeDebounce?.cancel();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    _likeDebounce?.cancel();

    _likeDebounce = Timer(const Duration(milliseconds: 300), () {
      widget.onLikePressed(widget.book['id'] ?? (widget.book as DocumentSnapshot).id);
    });
  }

  // Remplacer la méthode _handleContactPublisher
  Future<void> _handleContactPublisher() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté pour contacter un publiateur')),
        );
        return;
      }

      // Vérifier si l'utilisateur essaie de se contacter lui-même
      final publisherUserId = widget.book['userId'] ?? '';
      if (publisherUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de contacter le vendeur - userId manquant')),
        );
        return;
      }

      if (currentUser.uid == publisherUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous ne pouvez pas vous contacter vous-même')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Utiliser le userId du livre
      final chatId = await ChatService.getOrCreateChat(
        currentUser.uid,
        publisherUserId,
        widget.book['publisherName'],
      );

      Navigator.of(context, rootNavigator: true).pop();

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
            chatId: chatId,
            otherUserId: publisherUserId,
            otherUserName: widget.book['publisherName'],
            initialMessage: 'Bonjour, je suis intéressé par votre livre "${widget.book['title']}"',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutQuart;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookData = _extractBookData();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withOpacity(_isHovered ? 0.2 : 0.1),
                    blurRadius: _isHovered ? 25 : 20,
                    spreadRadius: _isHovered ? 0.5 : 0,
                    offset: Offset(0, _isHovered ? 12 : 8),
                  ),
                ],
                gradient: _isHovered
                    ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.blue.shade50,
                  ],
                )
                    : null,
              ),
              transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _showBookDetails(context, bookData),
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.blue.withOpacity(0.1),
                  splashColor: Colors.blue.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (bookData['isPopular']) _buildPopularBadge(),
                        _buildBookContent(bookData),
                        const SizedBox(height: 12),
                        _buildFooter(bookData),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFC400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const RadialGradient(
              center: Alignment.topLeft,
              colors: [Colors.white, Colors.amber],
              tileMode: TileMode.mirror,
            ).createShader(bounds),
            child: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            'POPULAIRE',
            style: widget.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookContent(Map<String, dynamic> bookData) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookImage(bookData['imageUrl'], size: 80, height: 100),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleAuthorSection(bookData),
                  const SizedBox(height: 8),
                  _buildConditionTypeChips(bookData),
                  const SizedBox(height: 12),
                  _buildDescription(bookData),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPriceRatingSection(bookData),
      ],
    );
  }

  Widget _buildTitleAuthorSection(Map<String, dynamic> bookData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: widget.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF1A237E),
            height: 1.3,
            shadows: _isHovered ? [
              Shadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ] : null,
          ) ?? TextStyle(),
          child: Text(
            bookData['title'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'par ${bookData['author']}',
          style: widget.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF546E7A),
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildConditionTypeChips(Map<String, dynamic> bookData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildInfoChip(
            Icons.auto_awesome_rounded,
            bookData['condition'],
            const Color(0xFF1976D2),
          ),
          const SizedBox(width: 8),
          _buildInfoChip(
            bookData['type'] == 'Échange'
                ? Icons.swap_horiz_rounded
                : Icons.attach_money_rounded,
            bookData['type'],
            const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Map<String, dynamic> bookData) {
    return Text(
      bookData['description'],
      style: widget.textTheme.bodySmall?.copyWith(
        color: const Color(0xFF607D8B),
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceRatingSection(Map<String, dynamic> bookData) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${bookData['price']} ',
                  style: widget.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1976D2),
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: 'FCFA',
                  style: widget.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF78909C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            _buildRatingStars(bookData['rating']),
            const SizedBox(width: 16),
            _buildLikeButton(bookData['id'], bookData['likes']),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(Map<String, dynamic> bookData) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'Publié par ${bookData['publisherName']}',
            style: widget.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF90A4AE),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        Text(
          '${bookData['pages']} pages',
          style: widget.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF78909C),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: _isHovered ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: widget.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    final starCount = (rating / 20).clamp(0, 5).toInt();
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          size: 18,
          color: starCount > 0 ? Colors.amber : Colors.grey[300],
        ),
        const SizedBox(width: 4),
        Text(
          (rating / 20).toStringAsFixed(1),
          style: widget.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.amber[800],
          ),
        ),
      ],
    );
  }

  Widget _buildLikeButton(String bookId, int likes) {
    return InkWell(
      onTap: _handleLike,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isLiked
              ? Colors.pink.withOpacity(0.15)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isLiked
                ? Colors.pink.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: (_isLiked ? Colors.pink : Colors.grey).withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey<bool>(_isLiked),
                size: 18,
                color: _isLiked ? Colors.pink[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 6),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: Text(
                (_isLiked ? likes : likes).toString(),
                style: widget.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _isLiked ? Colors.pink[600] : Colors.grey[600],
                ),
              ),
              secondChild: Text(
                (_isLiked ? likes : likes).toString(),
                style: widget.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _isLiked ? Colors.pink[600] : Colors.grey[600],
                ),
              ),
              crossFadeState: _isLiked ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage(String? base64Data, {double size = 80, double height = 100}) {
    return Hero(
      tag: 'book-image-${widget.book['id']}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (base64Data != null && base64Data.isNotEmpty)
                  Positioned.fill(
                    child: Image.memory(
                      base64.decode(base64Data),
                      fit: BoxFit.cover,
                      width: size,
                      height: height,
                    ),
                  ),

                if (base64Data != null && base64Data.isNotEmpty)
                  Image.memory(
                    base64.decode(base64Data),
                    fit: BoxFit.cover,
                    width: size,
                    height: height,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderIcon();
                    },
                  )
                else
                  _buildPlaceholderIcon(),

                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isHovered ? 0.1 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.book, color: Colors.grey, size: 32),
    );
  }

  void _showBookDetails(BuildContext context, Map<String, dynamic> bookData) {
    final isOwner = widget.currentUserId == widget.book['publisherEmail'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BookDetailsModal(
          books: widget.book,
          bookData: bookData,
          isOwner: isOwner,
          currentUserId: widget.currentUserId,
          onEditBook: widget.onEditBook,
          onDeleteBook: widget.onDeleteBook,
          onContactPublisher: _handleContactPublisher,
        );
      },
    );
  }

  Map<String, dynamic> _extractBookData() {
    dynamic rating = widget.book['rating'];
    double finalRating = 0.0;

    if (rating != null) {
      if (rating is int) {
        finalRating = rating.toDouble();
      } else if (rating is double) {
        finalRating = rating;
      }
    }

    String bookId = '';
    if (widget.book is DocumentSnapshot) {
      bookId = (widget.book as DocumentSnapshot).id;
    } else if (widget.book['id'] is String) {
      bookId = widget.book['id'];
    }

    return {
      'imageUrl': widget.book['imageUrl'] as String? ?? '',
      'title': widget.book['title'] as String? ?? 'Titre non spécifié',
      'author': widget.book['author'] as String? ?? 'Auteur inconnu',
      'publisherName': widget.book['publisherName'] as String? ?? 'Anonyme',
      'description': widget.book['description'] as String? ?? 'Description non disponible',
      'rating': finalRating,
      'category': widget.book['category'] as String? ?? 'Non catégorisé',
      'isPopular': widget.book['isPopular'] as bool? ?? false,
      'likes': (widget.book['likes'] as int?) ?? 0,
      'id': bookId,
      'price': (widget.book['price'] is int ? widget.book['price'] as int? :
      widget.book['price'] is double ? (widget.book['price'] as double).toInt() : 0) ?? 0,
      'pages': (widget.book['pages'] is int ? widget.book['pages'] as int? :
      widget.book['pages'] is double ? (widget.book['pages'] as double).toInt() : 0) ?? 0,
      'condition': widget.book['condition'] as String? ?? 'Bon état',
      'type': widget.book['type'] as String? ?? 'Échange',
    };
  }
}