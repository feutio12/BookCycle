import 'package:flutter/material.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';
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
      title: 'Découvrez des milliers de livres',
      description: 'Accédez à une vaste collection de livres dans tous les genres',
      imagePath: 'assets/images/logo.png',
    ),
    OnboardingPage(
      title: 'Gérez votre bibliothèque',
      description: 'Organisez et suivez vos lectures facilement',
      imagePath: 'assets/images/sss.jpg',
    ),
    OnboardingPage(
      title: 'Partagez avec la communauté',
      description: 'Échangez avec d\'autres passionnés de lectures',
      imagePath: 'assets/images/Library-pana.png',
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
      backgroundColor: Colors.white,
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
                return OnboardingContent(page: pages[index]);
              },
            ),

            // Bouton en bas centré
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PageIndicator(
                      currentPage: controller.currentPage,
                      pageCount: pages.length,
                    ),
                    const SizedBox(height: 20),
                    OnboardingActionButton(
                      isLastPage: controller.currentPage == pages.length - 1,
                      onPressed: () {
                        if (controller.currentPage == pages.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
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
          ],
        ),
      ),
    );
  }
}