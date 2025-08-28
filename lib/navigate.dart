import 'package:bookcycle/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/composants/composant1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Navigate extends StatefulWidget {
  const Navigate({super.key});

  @override
  State<Navigate> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<Navigate> {

  Future<void> _finishOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacementNamed(context, '/authwrapper');
  }

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Découvrez BookCycle",
      description: "Échangez vos livres avec d'autres passionnés de lecture et donnez une nouvelle vie à votre bibliothèque.",
      image: "assets/images/BookCycle.png",
      color: Color(0xFF42A5F5),
    ),
    OnboardingPage(
      title: "Partagez sans limites",
      description: "Proposez vos livres à l'échange et trouvez ceux qui vous intéressent parmi des milliers d'ouvrages.",
      image: "assets/images/Library-pana.png",
      color: Color(0xFF42A5F5),
    ),
    OnboardingPage(
      title: "Rejoign la communauté",
      description: "Connectez-vous avec d'autres lecteurs, échangez vos avis et participez à des événements littéraires.",
      image: "assets/images/ccc.jpg",
      color: Color(0xFF42A5F5),
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageV
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);

            },
            itemBuilder: (context, index) {
              return OnboardingPageWidget(page: _pages[index]);
            },
          ),

          // Indic
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor:Color(0xFF1976D2),
                  dotColor: Colors.grey,
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 8,
                ),
              ),
            ),
          ),

          //bout
          Positioned(
            bottom: 70,
            left: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentPage == _pages.length - 1
                  ? CustomButtomNav(label: "Commencer", action: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => const Homepage()));
              }, background: _pages[_currentPage].color, large: 0.6):

              TextButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(
                  'Suivant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _pages[_currentPage].color,
                  ),
                ),
              ),
            ),
          ),

          // Bo Pass
          if (_currentPage != _pages.length - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: () {
                  _pageController.animateToPage(
                    _pages.length - 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(
                  'Passer',
                  style: TextStyle(
                    fontSize: 20,
                    color: _pages[_currentPage].color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String image;
  final String title;
  final String description;
  final Color color;

  const OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
    required this.color,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: page.color.withOpacity(0.1),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Image.asset(
                page.image,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Texte
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: page.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}