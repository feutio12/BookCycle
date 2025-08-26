import 'package:bookcycle/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/composants/composant1.dart';

class Navigate extends StatefulWidget {
  const Navigate({super.key});

  @override
  State<Navigate> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<Navigate> {
  late final OnboardingController controller;
  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: "Découvrez BookCycle",
      description: "Échangez vos livres avec d'autres passionnés de lecture et donnez une nouvelle vie à votre bibliothèque.",
      imagePath: "assets/images/BookCycle.png",
    ),
    OnboardingPage(
      title: "Partagez sans limites",
      description: "Proposez vos livres à l'échange et trouvez ceux qui vous intéressent parmi des milliers d'ouvrages.",
      imagePath: "assets/images/Library-pana.png",
    ),
    OnboardingPage(
      title: "Rejoignez la communauté",
      description: "Connectez-vous avec d'autres lecteurs, échangez vos avis et participez à des événements littéraires.",
      imagePath: "assets/images/ccc.jpg",
    ),
  ];

  @override
  void initState() {
    super.initState();
    controller = OnboardingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF), // Fond bleu très clair
      body: SafeArea(
        child: Stack(
          children: [
            // PageView avec physique personnalisée
            PageView.builder(
              controller: controller.pageController,
              itemCount: pages.length,
              physics: const ClampingScrollPhysics(), // Empêche le défilement élastique
              onPageChanged: (index) {
                setState(() {
                  controller.currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return OnboardingContent(
                  page: pages[index],
                  pageIndex: index, onNextPressed: () {  },
                );
              },
            ),

            // Bouton en bas centré
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 40),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PageIndicator(
                      currentPage: controller.currentPage,
                      pageCount: pages.length,
                    ),
                    const SizedBox(height: 30),
                    OnboardingActionButton(
                      isLastPage: controller.currentPage == pages.length - 1,
                      onPressed: () {
                        if (controller.currentPage == pages.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Homepage()),
                          );
                        } else {
                          controller.nextPage();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bouton de saut en haut à droite (seulement sur les premières pages)
            if (controller.currentPage < pages.length - 1)
              Positioned(
                top: 20,
                right: 20,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Homepage()),
                    );
                  },
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}