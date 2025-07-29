import 'package:flutter/material.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';

class Navigate extends StatefulWidget {
  const Navigate({super.key});

  @override
  State<Navigate> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<Navigate> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Découvrez des milliers de livres',
      'description': 'Accédez à une vaste collection de livres dans tous les genres',
      'image': 'assets/images/ccc.jpg',
    },
    {
      'title': 'Gérez votre bibliothèque',
      'description': 'Organisez et suivez vos lectures facilement',
      'image': 'assets/images/sss.jpg',
    },
    {
      'title': 'Partagez avec la communauté',
      'description': 'Échangez avec d\'autres passionnés de lecture',
      'image': 'assets/images/Library-pana.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final greyColor = theme.hintColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // PageView pour les slides
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SingleOnboardingPage(
                    title: data['title'] ?? '',
                    description: data['description'] ?? '',
                    image: data['image'] ?? '',
                  ),
                ],
              );
            },
          ),

          // Positionnement des indicateurs et boutons
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Indicateurs de page (les trois points)
              Container(
                margin: const EdgeInsets.only(bottom: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 10 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.blue
                            : greyColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Bouton Commencer/Suivant
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentPage == _onboardingData.length - 1
                      ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Loginpage(),
                          ),
                        );
                      },
                      child: const Text(
                        'COMMENCER',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                      : Align(
                    alignment: Alignment.center,
                    child: FloatingActionButton(
                      backgroundColor: Colors.blue,
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      },
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SingleOnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const SingleOnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image avec gestion d'erreur
          Image.asset(
            image,
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 300,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}