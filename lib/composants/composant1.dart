import 'package:flutter/material.dart';
import 'package:bookcycle/main.dart';

// Classe représentant une page d'onboarding
class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

// Contrôleur pour gérer la logique d'onboarding
class OnboardingController {
  final PageController pageController;
  int currentPage;

  OnboardingController()
      : pageController = PageController(),
        currentPage = 0;

  void nextPage() {
    if (currentPage < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      currentPage++;
    }
  }

  void dispose() {
    pageController.dispose();
  }
}

// Widget pour l'indicateur de page
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 14 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? const Color(0xFF1976D2) // Bleu principal
                : const Color(0xFFBBDEFB), // Bleu clair
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// Widget pour le contenu d'une page d'onboarding
class OnboardingContent extends StatelessWidget {
  final OnboardingPage page;
  final int pageIndex;
  final VoidCallback onNextPressed;

  const OnboardingContent({
    super.key,
    required this.page,
    required this.pageIndex,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F9FF), // Fond bleu très clair
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Section supérieure avec l'image
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Hero(
                tag: 'book-image',
                child: Image.asset(
                  page.imagePath,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.book, size: 60, color: Color(0xFF1976D2)),
                  ),
                ),
              ),
            ),
          ),

          // Section centrale avec le contenu textuel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Séparateur décoratif
                  Container(
                    width: 60,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Titre
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1976D2), // Bleu principal
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section inférieure avec l'indicateur et le bouton
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                // Indicateur de page (uniquement ici, pas dans la section centrale)
                PageIndicator(
                  currentPage: pageIndex,
                  pageCount: 3,
                ),

                const SizedBox(height: 30),

                // Bouton d'action
                OnboardingActionButton(
                  isLastPage: pageIndex == 2,
                  onPressed: onNextPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour le bouton d'action
class OnboardingActionButton extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onPressed;

  const OnboardingActionButton({
    super.key,
    required this.isLastPage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLastPage
          ? ElevatedButton(
        key: const ValueKey('commencer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2), // Bleu principal
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: const Text(
          'COMMENCER',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : ElevatedButton(
        key: const ValueKey('next'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Suivant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}
