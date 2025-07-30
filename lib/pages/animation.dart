import 'package:flutter/material.dart';
import 'package:bookcycle/navigate.dart';
import 'dart:math';

class SplashAnimation extends StatefulWidget {
  const SplashAnimation({super.key});

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _bookFlipAnimation;
  late final Animation<Color?> _colorAnimation;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 50),
      ],
    ).animate(_controller);

    _fadeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 60),
      ],
    ).animate(_controller);

    _bookFlipAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.blue[700],
      end: Colors.blue[800],
    ).animate(_controller);

    // Gestion sécurisée de la navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 4)).then((_) {
        if (mounted) {
          Navigator.of(_navigatorKey.currentContext!).pushReplacement(
            MaterialPageRoute(builder: (context) => const Navigate()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Animation de livre qui s'ouvre
                  Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_bookFlipAnimation.value * pi),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Icon(
                        Icons.menu_book,
                        size: 150,
                        color: _colorAnimation.value,
                      ),
                    ),
                  ),

                  // Texte avec effets combinés
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Text(
                        'BookCycle',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Color.lerp(Colors.lightBlue, Colors.transparent, 0.5)!,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Effet de pages volantes
                  ...List.generate(5, (index) {
                    final angle = _controller.value * 2 * pi + (index * 0.5);
                    final offset = Offset(
                      50 * cos(angle),
                      50 * sin(angle),
                    );
                    return Positioned(
                      left: MediaQuery.of(context).size.width / 2 + offset.dx,
                      top: MediaQuery.of(context).size.height / 2 + offset.dy,
                      child: Transform.rotate(
                        angle: angle,
                        child: Opacity(
                          opacity: 0.6 - (index * 0.1),
                          child: Icon(
                            Icons.book,
                            size: 24,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

